# Backend API pour l'intégration Flinks

Voici un exemple d'implémentation backend (Node.js/Express) pour gérer l'intégration Flinks de manière sécurisée :

## Structure des endpoints requis

### 1. POST /api/flinks/initiate
Initie une connexion Flinks et retourne l'URL de connexion.

```javascript
app.post('/api/flinks/initiate', async (req, res) => {
  try {
    const { customerId } = req.body;
    
    const response = await fetch('https://sandbox.flinks.io/v3/Authorize', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        CustomerId: process.env.FLINKS_CUSTOMER_ID,
        Institution: 'FlinksCapital', // ou autre institution
        Language: 'fr',
        RedirectURI: `${process.env.BASE_URL}/flinks/callback`,
      }),
    });

    const data = await response.json();
    
    if (data.HttpStatusCode === 200) {
      res.json({
        success: true,
        loginUrl: data.LoginUrl,
        requestId: data.RequestId,
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Erreur lors de l\'initiation de la connexion',
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});
```

### 2. GET /api/flinks/status/:requestId
Vérifie le statut de la connexion.

```javascript
app.get('/api/flinks/status/:requestId', async (req, res) => {
  try {
    const { requestId } = req.params;
    
    const response = await fetch('https://sandbox.flinks.io/v3/GetAccountsDetail', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        RequestId: requestId,
      }),
    });

    const data = await response.json();
    
    res.json({
      connected: data.HttpStatusCode === 200,
      accounts: data.Accounts || [],
    });
  } catch (error) {
    res.status(500).json({
      connected: false,
      error: error.message,
    });
  }
});
```

### 3. GET /api/flinks/accounts
Récupère les comptes connectés.

```javascript
app.get('/api/flinks/accounts', async (req, res) => {
  try {
    // Récupérer les comptes depuis votre base de données
    const accounts = await getUserConnectedAccounts(req.user.id);
    
    res.json({
      accounts: accounts,
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});
```

### 4. POST /api/flinks/sync
Synchronise les transactions.

```javascript
app.post('/api/flinks/sync', async (req, res) => {
  try {
    const userAccounts = await getUserConnectedAccounts(req.user.id);
    const allTransactions = [];
    
    for (const account of userAccounts) {
      const response = await fetch('https://sandbox.flinks.io/v3/GetAccountsDetail', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          RequestId: account.requestId,
          WithTransactions: true,
          DaysOfTransactions: 30, // Derniers 30 jours
        }),
      });

      const data = await response.json();
      
      if (data.HttpStatusCode === 200 && data.Accounts) {
        for (const acc of data.Accounts) {
          if (acc.Transactions) {
            // Filtrer les transactions de débit (achats)
            const purchases = acc.Transactions.filter(t => 
              t.Debit && t.Debit > 0 && 
              !t.Description.toLowerCase().includes('transfer') &&
              !t.Description.toLowerCase().includes('payment')
            );
            
            allTransactions.push(...purchases.map(t => ({
              id: t.Id,
              date: t.Date,
              amount: t.Debit,
              description: t.Description,
              accountId: acc.Id,
            })));
          }
        }
      }
    }
    
    res.json({
      transactions: allTransactions,
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
    });
  }
});
```

### 5. DELETE /api/flinks/accounts/:accountId
Déconnecte un compte.

```javascript
app.delete('/api/flinks/accounts/:accountId', async (req, res) => {
  try {
    const { accountId } = req.params;
    
    // Supprimer le compte de votre base de données
    await removeUserAccount(req.user.id, accountId);
    
    res.json({
      success: true,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

## Configuration requise

### Variables d'environnement
```
FLINKS_CUSTOMER_ID=your_customer_id
FLINKS_CLIENT_ID=your_client_id  
FLINKS_CLIENT_SECRET=your_client_secret
BASE_URL=https://your-backend-url.com
```

### Base de données
Créez une table pour stocker les connexions bancaires :

```sql
CREATE TABLE user_bank_connections (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  request_id VARCHAR(255) NOT NULL,
  institution_name VARCHAR(255),
  account_id VARCHAR(255),
  account_number VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Sécurité

1. **Authentification** : Assurez-vous que tous les endpoints sont protégés par authentification
2. **Chiffrement** : Chiffrez les données sensibles en base
3. **HTTPS** : Utilisez uniquement HTTPS en production
4. **Rate limiting** : Implémentez une limitation du taux de requêtes
5. **Validation** : Validez toutes les entrées utilisateur

## Webhook (optionnel)

Pour une synchronisation en temps réel, configurez un webhook Flinks :

```javascript
app.post('/api/flinks/webhook', async (req, res) => {
  try {
    const { RequestId, Event } = req.body;
    
    if (Event === 'TransactionUpdate') {
      // Déclencher une synchronisation pour cet utilisateur
      await triggerUserSync(RequestId);
    }
    
    res.status(200).send('OK');
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

Cette implémentation backend assure la sécurité des données bancaires tout en permettant une intégration fluide avec l'application Flutter.