/*
Create a secret in an existing Key Vault

@parameters 
  kvName: String the existing KV name
  secretName: String the name of the secret to be created
  secretValue: Secure string containing the secret value. If not supplied a random GUID is generated.
  secretexpdate: Expiry date of the secret since 1970, this is the only format the parameter accepts value. For 12 months this is 31556952, set expiry date for secret multiply 31556952 x Number of months from the date

*/
param kvName string
param secretName string
@secure()
param secretValue string = '${newGuid()}${utcNow()}'
param secretExpDate int

resource my_test_secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${kvName}/${secretName}'
  properties: {
    value: secretValue
    attributes: {
      enabled: true
      exp: secretExpDate
    }
  }
}
