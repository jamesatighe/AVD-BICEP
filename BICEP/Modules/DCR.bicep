//***********************************************************************************************************************
//Parameters - All
param location string

@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false

@description('Log Analytics Workspace ID')
param workspaceID string

@description('Log Analytics Workspace Resource Id')
param logAnalyticsResourceId string

//***********************************************************************************************************************
//Resources - Data Collection Rule
resource SessionHostDCR 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = if (monitoringAgent == true) {
  name: 'SessionHostDCR'
  location: location
  tags: {
    Owner: 'James Tighe'
    Environment: 'Production'
  }
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'PerformanceCounters_60'
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\LogicalDisk(C:)\\% Free Space'
            '\\Terminal Services(*)\\Active Sessions'
            '\\Terminal Services(*)\\Inactive Sessions'
            '\\Terminal Services(*)\\Total Sessions'
            '\\LogicalDisk(C:)\\Avg. Disk sec/Transfer'
          ]
          platformType: 'Windows'
        }
        {
          name: 'PerformanceCounters_10'
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 10
          counterSpecifiers: [
            '\\PhysicalDisk(*)\\Avg. Disk sec/Read'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Transfer'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Write'
            '\\Processor Information(_Total)\\% Processor Time'
            '\\LogicalDisk(C:)\\Avg. Disk Queue Length'
            '\\User Input Delay per Process(*)\\Max Input Delay'
            '\\User Input Delay per Session(*)\\Max Input Delay'
            '\\RemoteFX Network(*)\\Current TCP RTT'
            '\\RemoteFX Network(*)\\Current UDP Bandwidth'
            '\\LogicalDisk(C:)\\Current Disk Queue Length'
            '\\Memory\\Available Mbytes'
            '\\Memory\\Page Faults/sec'
            '\\Memory\\Pages/sec'
            '\\Memory\\% Committed Bytes In Use'
            '\\PhysicalDisk(*)\\Avg. Disk Queue Length'
          ]
          platformType: 'Windows'
        }
      ]
      windowsEventLogs: [
        {
          name: 'SessionHostLogs'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Admin!*[System[(Level=1 or Level=2 or Level=4 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=1 or Level=2 or Level=4 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=1 or Level=2 or Level=4 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=1 or Level=2 or Level=4 or Level=3)]]'
          ]
        }
      ]
    }
    description: 'Data Collection Rule for AVD Session Host Monitoring'
    destinations: {
      logAnalytics: [
        {
          name: 'LogAnalytics'
          workspaceResourceId: logAnalyticsResourceId
          workspaceId: workspaceID
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
        ]
        destinations: [
          'LogAnalytics'
        ]
      }
    ]
  }
}

//***********************************************************************************************************************
//Output - All
output DCRId string = SessionHostDCR.id
