targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.netapp.netappaccounts-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'nanaanfs3'

// =========== //
// Deployments //
// =========== //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module resourceGroupResources 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-paramNested'
  params: {
    virtualNetworkName: 'dep-<<namePrefix>>-vnet-${serviceShort}'
    managedIdentityName: 'dep-<<namePrefix>>-msi-${serviceShort}'
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name)}-test-${serviceShort}'
  params: {
    name: '<<namePrefix>>${serviceShort}001'
    capacityPools: [
      {
        name: '<<namePrefix>>-${serviceShort}-cp-001'
        roleAssignments: [
          {
            roleDefinitionIdOrName: 'Reader'
            principalIds: [
              resourceGroupResources.outputs.managedIdentityPrincipalId
            ]
            principalType: 'ServicePrincipal'
          }
        ]
        serviceLevel: 'Premium'
        size: 4398046511104
        volumes: [
          {
            exportPolicyRules: [
              {
                allowedClients: '0.0.0.0/0'
                nfsv3: true
                nfsv41: false
                ruleIndex: 1
                unixReadOnly: false
                unixReadWrite: true
              }
            ]
            name: '<<namePrefix>>-${serviceShort}-vol-001'
            protocolTypes: [
              'NFSv3'
            ]
            roleAssignments: [
              {
                roleDefinitionIdOrName: 'Reader'
                principalIds: [
                  resourceGroupResources.outputs.managedIdentityPrincipalId
                ]
                principalType: 'ServicePrincipal'
              }
            ]
            subnetResourceId: resourceGroupResources.outputs.subnetResourceId
            usageThreshold: 107374182400
          }
          {
            name: '<<namePrefix>>-${serviceShort}-vol-002'
            protocolTypes: [
              'NFSv3'
            ]
            subnetResourceId: resourceGroupResources.outputs.subnetResourceId
            usageThreshold: 107374182400
          }
        ]
      }
      {
        name: '<<namePrefix>>-${serviceShort}-cp-002'
        roleAssignments: [
          {
            roleDefinitionIdOrName: 'Reader'
            principalIds: [
              resourceGroupResources.outputs.managedIdentityPrincipalId
            ]
            principalType: 'ServicePrincipal'
          }
        ]
        serviceLevel: 'Premium'
        size: 4398046511104
        volumes: []
      }
    ]
    lock: 'CanNotDelete'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          resourceGroupResources.outputs.managedIdentityPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    tags: {
      Contact: 'test.user@testcompany.com'
      CostCenter: '7890'
      Environment: 'Non-Prod'
      PurchaseOrder: '1234'
      Role: 'DeploymentValidation'
      ServiceName: 'DeploymentValidation'
    }
  }
}
