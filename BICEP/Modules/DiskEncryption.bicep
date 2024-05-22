@description('Location for KeyVault.')
param location string

@description('Key Vault Name for Disk Encryption.')
param keyVaultName string

@description('Key Vault Disk Encryption SKU')
@allowed([
  'standard'
  'premium'
])
param keyVaultSKU string

@description('The JsonWebKeyType of the key to be created.')
@allowed([
  'EC'
  'EC-HSM'
  'RSA'
  'RSA-HSM'
])
param keyType string

@description('Key Size.')
param keySize int

// Create the new KeyVault for the Disk Encryption Key
resource DiskKV 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []
    sku: {
      name: keyVaultSKU
      family: 'A'
    }
    tenantId: tenant().tenantId
    enabledForDiskEncryption: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
  }
}

// Create the Encryption Key itself
resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: DiskKV
  name: 'EncryptionKey'
  properties: {
    kty: keyType
    keySize: keySize
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
      'sign'
      'verify'
    ]
    
  }
}

//Disk Encryption Set
resource AVDDiskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-10-02' = {
  name: 'AVDDiskEncryptionSet'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
      activeKey: {
        keyUrl: encryptionKey.properties.keyUriWithVersion
        sourceVault: {
          id: DiskKV.id
        }
      }
      encryptionType: 'EncryptionAtRestWithCustomerKey'
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: DiskKV
  dependsOn: [
    AVDDiskEncryptionSet
  ]
  properties: {
    accessPolicies: [
      {
        objectId: AVDDiskEncryptionSet.identity.principalId
        tenantId: tenant().tenantId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
          certificates: []
          secrets: []
        }
      }
    ]
  }
}

output keyVaultUrl string = DiskKV.properties.vaultUri
output keyVaultResourceId string = DiskKV.id
output keyUrl string = encryptionKey.properties.keyUriWithVersion
