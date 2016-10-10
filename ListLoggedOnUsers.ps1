$ErrorActionPreference = "Stop"
$comps = Get-Content CRISUsers.txt
FOREACH ($comp in $comps) {
    IF(Test-Connection -count 1 -quiet $comp){
        TRY {$user = WMIC /NODE: $comp COMPUTERSYSTEM GET USERNAME}
        CATCH {$user = "ERROR"}
        FINALLY {"$comp = $user"}
    } ELSE {
        "$comp = Could Not Connect"
    }
}