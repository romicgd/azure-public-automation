WorkFlow Propagate-Billing-Fields
{
    Param
    (   
        [Parameter(Mandatory=$true)]
        [String]
        $AzureResourceGroup,
        [Parameter(Mandatory=$false)]
        [String]
        $PersistentTags = "application_id"
    )
    
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
  
    InlineScript {
        $appendpolicy = Get-AzureRmPolicyDefinition | Where-Object {$_.Name -eq '2a0e14a6-b0a6-4fab-991a-187a4f81c498'}
        $denypolicy = Get-AzureRmPolicyDefinition | Where-Object {$_.Name -eq '1e30110a-5ceb-460c-a204-c1c3969c6d62'}
        $createdPolicies = @()
        $PolicyTags = $Using:PersistentTags
        $PolicyTags = $PolicyTags.Split(",").Trim()
        
        $resourceGroup = Get-AzureRmResourceGroup -Name $Using:AzureResourceGroup
        $tags = $resourceGroup.Tags
    
        foreach($tag in $tags.GetEnumerator()){
            $key = $tag.Name
            $value = $tag.Value
            if($PolicyTags.Contains($key)){
                $createdPolicies += New-AzureRmPolicyAssignment -Name ("append"+$key+"tag") -PolicyDefinition $appendpolicy -Scope $resourceGroup.ResourceId -tagName $key -tagValue  $value
                $createdPolicies += New-AzureRmPolicyAssignment -Name ("denywithout"+$key+"tag") -PolicyDefinition $denypolicy -Scope $resourceGroup.ResourceId -tagName $key -tagValue  $value
                Write-Output "Persisting Tag $key = $value on ResourceGroup $resourceGroup"
            }else{
                Write-Output "[IGNORE] $key is not part of the PersistentTags. Ignoring. $value"
            }
        }
    }
    $createdPolicies
}