targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(80)
param resourceGroupName string = 'ms.automation.account-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'aacom'

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
    keyVaultName: 'dep-<<namePrefix>>-kv-${serviceShort}'
    managedIdentityName: 'dep-<<namePrefix>>-msi-${serviceShort}'
  }
}

// Diagnostics
// ===========
module diagnosticDependencies '../../../../.shared/dependencyConstructs/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagnosticDependencies'
  params: {
    storageAccountName: 'dep<<namePrefix>>diasa${serviceShort}01'
    logAnalyticsWorkspaceName: 'dep-<<namePrefix>>-law-${serviceShort}'
    eventHubNamespaceEventHubName: 'dep-<<namePrefix>>-evh-${serviceShort}'
    eventHubNamespaceName: 'dep-<<namePrefix>>-evhns-${serviceShort}'
    location: location
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
    diagnosticLogsRetentionInDays: 7
    diagnosticStorageAccountId: diagnosticDependencies.outputs.storageAccountResourceId
    diagnosticWorkspaceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    diagnosticEventHubAuthorizationRuleId: diagnosticDependencies.outputs.eventHubAuthorizationRuleId
    diagnosticEventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
    gallerySolutions: [
      {
        name: 'Updates'
        product: 'OMSGallery'
        publisher: 'Microsoft'
      }
    ]
    jobSchedules: [
      {
        runbookName: 'TestRunbook'
        scheduleName: 'TestSchedule'
      }
    ]
    disableLocalAuth: true
    linkedWorkspaceResourceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
    lock: 'CanNotDelete'
    modules: [
      {
        name: 'PSWindowsUpdate'
        uri: 'https://www.powershellgallery.com/api/v2/package'
        version: 'latest'
      }
    ]
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            resourceGroupResources.outputs.privateDNSZoneResourceId
          ]
        }
        service: 'Webhook'
        subnetResourceId: resourceGroupResources.outputs.subnetResourceId
      }
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            resourceGroupResources.outputs.privateDNSZoneResourceId
          ]
        }
        service: 'DSCAndHybridWorker'
        subnetResourceId: resourceGroupResources.outputs.subnetResourceId
      }
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
    runbooks: [
      {
        description: 'Test runbook'
        name: 'TestRunbook'
        runbookType: 'PowerShell'
        uri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.automation/101-automation/scripts/AzureAutomationTutorial.ps1'
        version: '1.0.0.0'
      }
    ]
    schedules: [
      {
        advancedSchedule: {}
        expiryTime: '9999-12-31T13:00'
        frequency: 'Minute'
        interval: 15
        name: 'TestSchedule'
        startTime: ''
        timeZone: 'Europe/Berlin'
      }
    ]
    softwareUpdateConfigurations: [
      {
        excludeUpdates: [
          '123456'
        ]
        frequency: 'Month'
        includeUpdates: [
          '654321'
        ]
        interval: 1
        maintenanceWindow: 'PT4H'
        monthlyOccurrences: [
          {
            day: 'Friday'
            occurrence: 3
          }
        ]
        name: 'Windows_ZeroDay'
        operatingSystem: 'Windows'
        rebootSetting: 'IfRequired'
        scopeByTags: {
          Update: [
            'Automatic-Wave1'
          ]
        }
        startTime: '22:00'
        updateClassifications: [
          'Critical'
          'Definition'
          'FeaturePack'
          'Security'
          'ServicePack'
          'Tools'
          'UpdateRollup'
          'Updates'
        ]
      }
      {
        excludeUpdates: [
          'icacls'
        ]
        frequency: 'OneTime'
        includeUpdates: [
          'kernel'
        ]
        maintenanceWindow: 'PT4H'
        name: 'Linux_ZeroDay'
        operatingSystem: 'Linux'
        rebootSetting: 'IfRequired'
        startTime: '22:00'
        updateClassifications: [
          'Critical'
          'Other'
          'Security'
        ]
      }
    ]
    systemAssignedIdentity: true
    userAssignedIdentities: {
      '${resourceGroupResources.outputs.managedIdentityResourceId}': {}
    }
    variables: [
      {
        description: 'TestStringDescription'
        name: 'TestString'
        value: '\'TestString\''
      }
      {
        description: 'TestIntegerDescription'
        name: 'TestInteger'
        value: '500'
      }
      {
        description: 'TestBooleanDescription'
        name: 'TestBoolean'
        value: 'false'
      }
      {
        description: 'TestDateTimeDescription'
        isEncrypted: false
        name: 'TestDateTime'
        value: '\'\\/Date(1637934042656)\\/\''
      }
      {
        description: 'TestEncryptedDescription'
        name: 'TestEncryptedVariable'
        value: '\'TestEncryptedValue\''
      }
    ]
  }
}
