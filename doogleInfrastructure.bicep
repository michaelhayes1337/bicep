@description('The name of the Virtual Machine for Subnet1')
param vm1Name string = 'vm1'

@description('The name of the Virtual Machine for Subnet2')
param vm2Name string = 'vm2'

@description('Username for the Virtual Machine')
param adminUsername string = 'michaelha'

@description('Type of authentication to use on the Virtual Machine. SSH Reccommended')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password vor the VM')
param adminPasswordOrKey string

@description('Unique DNS Name for the public IP used to access VM on Subnet 1')
param dnsLabelPrefixVm1 string = toLower('vm1-${uniqueString(resourceGroup().id)}')

@description('Ubuntu version of the VMs')
param ubuntuOSVersion string = '18.04-LTS'

@description('Location for all resources')
param location string = resourceGroup().location

@description('SIze of the VM')
param vmSize string = 'Standard_B2s'

@description('Name of the VNET')
param virtualNetworkName string = 'vNet'

@description('Name of subnet1')
param subnet1Name string = 'Subnet1'

@description('Name of subnet2')
param subnet2Name string = 'Subnet2'

@description('Name of Security Group for Subnet1')
param networkSecurityGroupName1 string = '${subnet1Name}--nsg'

@description('Name of Security Group for Subnet2')
param networkSecurityGroupName2 string = '${subnet2Name}--nsg'

var publicIPAddressNameVm1 = '${vm1Name}PublicIP'
var networkInterfaceNameVm1 = '${vm1Name}NetInt'
var networkInterfaceNameVm2 = '${vm2Name}NetInt'

var osDiskType = 'Standard_LRS'
var subnet1AddressPrefix = '10.1.0.0/24'
var subnet2AddressPrefix = '10.1.1.0/24'
var vNetAddressPrefix = '10.1.0.0/16'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource nic1 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: networkInterfaceNameVm1
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet1.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id: publicIP1.id
          }
        }
      }
    ]
    networkSecurityGroup:{
      id: nsg1.id
    }
  }
}
resource nsg1 'Microsoft.Network/networkSecurityGroups@2022-01-01'={
  name: networkSecurityGroupName1
  location:location
  properties:{
    securityRules:[
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: networkInterfaceNameVm2
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet2.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup:{
      id: nsg2.id
    }
  }
}

resource nsg2 'Microsoft.Network/networkSecurityGroups@2022-01-01'={
  name: networkSecurityGroupName2
  location:location
  properties:{
    securityRules:[
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
      }
      }
    ]
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2022-01-01'={
  name: virtualNetworkName
  location:location
  properties:{
    addressSpace:{
      addressPrefixes:[
        vNetAddressPrefix
      ]
    }
  }
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2022-01-01'={
  parent: vNet
  name:subnet1Name
  properties:{
    addressPrefix: subnet1AddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2022-01-01'={
  parent: vNet
  name:subnet2Name
  properties:{
    addressPrefix: subnet2AddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource publicIP1 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressNameVm1
  location: location
  sku:{
    name:'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefixVm1
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vm1Name
  location: location
  properties:{
    hardwareProfile:{
      vmSize: vmSize
    }
    storageProfile:{
      osDisk:{
        createOption:'FromImage'
        managedDisk:{
          storageAccountType: osDiskType
        }
      }
      imageReference:{
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version:'latest'
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id: nic1.id
        }
      ]
    }
    osProfile:{
      computerName: vm1Name
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: any(authenticationType=='password'? null: linuxConfiguration)
    }
  }
}

resource vm2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vm1Name
  location: location
  properties:{
    hardwareProfile:{
      vmSize: vmSize
    }
    storageProfile:{
      osDisk:{
        createOption:'FromImage'
        managedDisk:{
          storageAccountType: osDiskType
        }
      }
      imageReference:{
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version:'latest'
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id: nic2.id
        }
      ]
    }
    osProfile:{
      computerName: vm2Name
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: any(authenticationType=='password'? null: linuxConfiguration)
    }
  }
}

output hostname1 string = publicIP1.properties.dnsSettings.fqdn
