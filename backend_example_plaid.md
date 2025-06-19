# Backend API pour l'intégration Plaid

Voici un exemple d'implémentation backend (Node.js/Express) pour gérer l'intégration Plaid de manière sécurisée :

## Installation des dépendances

```bash
npm install express plaid dotenv cors helmet
```

## Structure des endpoints requis

### 1. POST /api/plaid/create-link-token
Crée un Link Token pour initier la connexion Plaid.

```javascript
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');

const configuration = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV || 'sandbox'],
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
});

const client = new PlaidApi(configuration);

app.post('/api/plaid/create-link-token', async (req, res) => {
  try {
    const { userId } = req.body;
    
    const request = {
      user: {
        client_user_id: userId,
      },
      client_name: 'Receipt Scanner',
      products: ['transactions'],
      country_codes: ['CA'], // Canada
      language: 'fr',
      webhook: `${process.env.BASE_URL}/api/plaid/webhook`,
    };

    const response = await client.linkTokenCreate(request);
    
    res.json({
      success: true,
      link_token: response.data.link_token,
      expiration: response.data.expiration,
    });
  } catch (error) {
    console.error('Error creating link token:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du token',
      error: error.message,
    });
  }
});
```

### 2. POST /api/plaid/exchange-public-token
Échange le public token contre un access token.

```javascript
app.post('/api/plaid/exchange-public-token', async (req, res) => {
  try {
    const { publicToken } = req.body;
    
    const request = {
      public_token: publicToken,
    };

    const response = await client.itemPublicTokenExchange(request);
    const accessToken = response.data.access_token;
    const itemId = response.data.item_id;
    
    // Stocker l'access token de manière sécurisée dans votre base de données
    await storeUserAccessToken(req.user.id, accessToken, itemId);
    
    res.json({
      success: true,
      message: 'Connexion établie avec succès',
    });
  } catch (error) {
    console.error('Error exchanging public token:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'échange du token',
      error: error.message,
    });
  }
});
```

### 3. GET /api/plaid/accounts
Récupère les comptes connectés.

```javascript
app.get('/api/plaid/accounts', async (req, res) => {
  try {
    const userTokens = await getUserAccessTokens(req.user.id);
    const allAccounts = [];
    
    for (const tokenData of userTokens) {
      const request = {
        access_token: tokenData.access_token,
      };
      
      const response = await client.accountsGet(request);
      const accounts = response.data.accounts.map(account => ({
        account_id: account.account_id,
        name: account.name,
        official_name: account.official_name,
        type: account.type,
        subtype: account.subtype,
        mask: account.mask,
        institution_name: tokenData.institution_name,
        item_id: tokenData.item_id,
      }));
      
      allAccounts.push(...accounts);
    }
    
    res.json({
      accounts: allAccounts,
    });
  } catch (error) {
    console.error('Error getting accounts:', error);
    res.status(500).json({
      error: error.message,
    });
  }
});
```

### 4. POST /api/plaid/transactions
Synchronise les transactions.

```javascript
app.post('/api/plaid/transactions', async (req, res) => {
  try {
    const { startDate, endDate } = req.body;
    const userTokens = await getUserAccessTokens(req.user.id);
    const allTransactions = [];
    
    for (const tokenData of userTokens) {
      const request = {
        access_token: tokenData.access_token,
        start_date: startDate,
        end_date: endDate,
        count: 500,
        offset: 0,
      };
      
      const response = await client.transactionsGet(request);
      
      // Filtrer les transactions d'achat (montants positifs)
      const purchases = response.data.transactions.filter(transaction => 
        transaction.amount > 0 && 
        !transaction.category?.includes('Transfer') &&
        !transaction.category?.includes('Payment') &&
        !transaction.category?.includes('Deposit')
      );
      
      const formattedTransactions = purchases.map(transaction => ({
        transaction_id: transaction.transaction_id,
        account_id: transaction.account_id,
        amount: transaction.amount,
        date: transaction.date,
        name: transaction.name,
        merchant_name: transaction.merchant_name,
        category: transaction.category,
        iso_currency_code: transaction.iso_currency_code,
        account_owner: transaction.account_owner,
      }));
      
      allTransactions.push(...formattedTransactions);
    }
    
    res.json({
      transactions: allTransactions,
    });
  } catch (error) {
    console.error('Error getting transactions:', error);
    res.status(500).json({
      error: error.message,
    });
  }
});
```

### 5. DELETE /api/plaid/item/:itemId
Supprime un item (déconnecte un compte).

```javascript
app.delete('/api/plaid/item/:itemId', async (req, res) => {
  try {
    const { itemId } = req.params;
    const tokenData = await getUserAccessTokenByItemId(req.user.id, itemId);
    
    if (!tokenData) {
      return res.status(404).json({
        success: false,
        message: 'Item non trouvé',
      });
    }
    
    const request = {
      access_token: tokenData.access_token,
    };
    
    await client.itemRemove(request);
    await removeUserAccessToken(req.user.id, itemId);
    
    res.json({
      success: true,
      message: 'Compte déconnecté avec succès',
    });
  } catch (error) {
    console.error('Error removing item:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

### 6. GET /api/plaid/institution/:institutionId
Récupère les informations d'une institution.

```javascript
app.get('/api/plaid/institution/:institutionId', async (req, res) => {
  try {
    const { institutionId } = req.params;
    
    const request = {
      institution_id: institutionId,
      country_codes: ['CA'],
    };
    
    const response = await client.institutionsGetById(request);
    
    res.json({
      institution: {
        institution_id: response.data.institution.institution_id,
        name: response.data.institution.name,
        products: response.data.institution.products,
        country_codes: response.data.institution.country_codes,
      },
    });
  } catch (error) {
    console.error('Error getting institution:', error);
    res.status(500).json({
      error: error.message,
    });
  }
});
```

### 7. POST /api/plaid/webhook
Webhook pour les mises à jour en temps réel.

```javascript
app.post('/api/plaid/webhook', async (req, res) => {
  try {
    const { webhook_type, webhook_code, item_id } = req.body;
    
    console.log('Plaid webhook received:', {
      webhook_type,
      webhook_code,
      item_id,
    });
    
    if (webhook_type === 'TRANSACTIONS') {
      if (webhook_code === 'INITIAL_UPDATE' || webhook_code === 'HISTORICAL_UPDATE') {
        // Déclencher une synchronisation pour cet item
        await triggerTransactionSync(item_id);
      }
    }
    
    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: error.message });
  }
});
```

## Configuration requise

### Variables d'environnement
```
PLAID_CLIENT_ID=your_client_id
PLAID_SECRET=your_secret_key
PLAID_ENV=sandbox
BASE_URL=https://your-backend-url.com
```

### Base de données
Créez une table pour stocker les access tokens :

```sql
CREATE TABLE user_plaid_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  access_token VARCHAR(255) NOT NULL,
  item_id VARCHAR(255) NOT NULL,
  institution_id VARCHAR(255),
  institution_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, item_id)
);

CREATE INDEX idx_user_plaid_tokens_user_id ON user_plaid_tokens(user_id);
CREATE INDEX idx_user_plaid_tokens_item_id ON user_plaid_tokens(item_id);
```

## Fonctions utilitaires

```javascript
// Stocker l'access token
async function storeUserAccessToken(userId, accessToken, itemId) {
  // Récupérer les informations de l'institution
  const itemRequest = { access_token: accessToken };
  const itemResponse = await client.itemGet(itemRequest);
  const institutionId = itemResponse.data.item.institution_id;
  
  const institutionRequest = {
    institution_id: institutionId,
    country_codes: ['CA'],
  };
  const institutionResponse = await client.institutionsGetById(institutionRequest);
  const institutionName = institutionResponse.data.institution.name;
  
  // Stocker en base de données
  await db.query(`
    INSERT INTO user_plaid_tokens (user_id, access_token, item_id, institution_id, institution_name)
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (user_id, item_id) 
    DO UPDATE SET access_token = $2, updated_at = CURRENT_TIMESTAMP
  `, [userId, accessToken, itemId, institutionId, institutionName]);
}

// Récupérer les access tokens d'un utilisateur
async function getUserAccessTokens(userId) {
  const result = await db.query(`
    SELECT access_token, item_id, institution_name 
    FROM user_plaid_tokens 
    WHERE user_id = $1
  `, [userId]);
  
  return result.rows;
}

// Supprimer un access token
async function removeUserAccessToken(userId, itemId) {
  await db.query(`
    DELETE FROM user_plaid_tokens 
    WHERE user_id = $1 AND item_id = $2
  `, [userId, itemId]);
}
```

## Sécurité

1. **Chiffrement** : Chiffrez les access tokens en base de données
2. **HTTPS** : Utilisez uniquement HTTPS en production
3. **Rate limiting** : Implémentez une limitation du taux de requêtes
4. **Validation** : Validez toutes les entrées utilisateur
5. **Webhook verification** : Vérifiez l'authenticité des webhooks Plaid
6. **Environment** : Utilisez `sandbox` pour le développement et `production` pour la production

## Environnements Plaid

- **Sandbox** : Pour le développement et les tests
- **Development** : Pour les tests avec de vraies institutions mais des données fictives
- **Production** : Pour l'environnement de production avec de vraies données

Cette implémentation backend assure la sécurité des données bancaires tout en permettant une intégration fluide avec l'application Flutter via Plaid.