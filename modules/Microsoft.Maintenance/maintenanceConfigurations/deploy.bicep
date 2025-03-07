// ============== //
//   Parameters   //
// ============== //

@description('Required. Maintenance Configuration Name.')
param name string

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. Gets or sets extensionProperties of the maintenanceConfiguration.')
param extensionProperties object = {}

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Specify the type of lock.')
@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
param lock string = ''

@description('Optional. Gets or sets maintenanceScope of the configuration.')
@allowed([
  'Host'
  'OSImage'
  'Extension'
  'InGuestPatch'
  'SQLDB'
  'SQLManagedInstance'
])
param maintenanceScope string = 'Host'

@description('Optional. Definition of a MaintenanceWindow.')
param maintenanceWindow object = {}

@description('Optional. Gets or sets namespace of the resource.')
param namespace string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Gets or sets tags of the resource.')
param tags object = {}

@description('Optional. Gets or sets the visibility of the configuration. The default value is \'Custom\'.')
@allowed([
  ''
  'Custom'
  'Public'
])
param visibility string = ''

// =============== //
//   Deployments   //
// =============== //

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource maintenanceConfiguration 'Microsoft.Maintenance/maintenanceConfigurations@2021-05-01' = {
  location: location
  name: name
  tags: tags
  properties: {
    extensionProperties: extensionProperties
    maintenanceScope: maintenanceScope
    maintenanceWindow: maintenanceWindow
    namespace: namespace
    visibility: visibility
  }
}

resource maintenanceConfiguration_lock 'Microsoft.Authorization/locks@2017-04-01' = if (!empty(lock)) {
  name: '${maintenanceConfiguration.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: maintenanceConfiguration
}

module maintenanceConfiguration_roleAssignments '.bicep/nested_roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-maintenanceConfiguration-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    delegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId') ? roleAssignment.delegatedManagedIdentityResourceId : ''
    resourceId: maintenanceConfiguration.id
  }
}]

// =========== //
//   Outputs   //
// =========== //

@description('The name of the Maintenance Configuration.')
output name string = maintenanceConfiguration.name

@description('The resource ID of the Maintenance Configuration.')
output resourceId string = maintenanceConfiguration.id

@description('The name of the resource group the Maintenance Configuration was created in.')
output resourceGroupName string = resourceGroup().name

@description('The location the Maintenance Configuration was created in.')
output location string = maintenanceConfiguration.location
