$folder = ".\" #$args[0]
#e.g. c:\temp\
if (!$folder.EndsWith('\'))
{
    $folder +="\"
}

$folderall = $folder + "*.*"
$filelist = Get-ChildItem -Path $folderall -include *_snap.log | select name

[PSObject[]] $threadCollection = @()
$threadCollection.g

$threadList = New-Object "System.Collections.Hashtable"
$topFrameList = New-Object "System.Collections.Hashtable"

foreach($name in $filelist)
{
    #$filePath = $args[0]
    $filePath = $folder + $name.name
    [xml]$xmlContent = Get-Content -LiteralPath $filePath;
    $frameList = New-Object "System.Collections.Hashtable"
    
    Write-Host "Analyzing files $filePath" #TODO
    Write-Host "Thread Count: " $xmlContent.snap.process.threads.count
    # Use this if you analyze EMON
    #foreach($thread in $xmlContent.exception_monitor.exeptions.exception)

    foreach($thread in $xmlContent.snap.process.threads.thread)
    {
        $topFrame = $true
        $customFrameFound = $false
        foreach($frame in $thread.stack.frames.frame)
        {
            # Damiano: consider only custom frames
            #if ($topFrame)
            #{
            #    $topFrameSignature = [String]::Concat($frame.method, $frame.arguments.count)
            #    $topFrame = $false
            #}
                        
            # Check for known assemblies System.*, Microsoft.*, ASP.* (however, Microsoft.Practices.* is included).
            if(($frame.method -notmatch "System.") -and ($frame.method -notmatch "Microsoft." -or $frame.method -match "Microsoft.Practices.") -and ($frame.method -notmatch "ASP."))
            {
                # Damiano: after considering only custom frames, now I determine the top custom frame
                if ($topFrame)
                {
                    $topFrameSignature = [String]::Concat($frame.method, $frame.arguments.count)
                    $topFrame = $false
                }

                $customFrameFound = $true

                # Include argument count, as overloads can exist
                $frameSignature = [String]::Concat($frame.method, $frame.arguments.count)
            
                # Count the inner frame signatures
                if($frameList.ContainsKey($frameSignature))
                {
                    [int]$counter = $frameList[$frameSignature]
                    $frameList[$frameSignature] = $counter+1
                }
                else
                {
                    $frameList.Add($frameSignature, 1)
                }
            }
        }

        if ($customFrameFound)
        {
            $threadTopFrameKey = $thread.id + " " + $topFrameSignature
            if($threadList.ContainsKey($threadTopFrameKey))
            {
                [int]$counter = $threadList[$threadTopFrameKey]
                $threadList[$threadTopFrameKey] = $counter+1
            }
            else
            {
                $threadList.Add($threadTopFrameKey, 1)
            }
            
            if($topFrameList.ContainsKey($topFrameSignature))
            {
                [int]$counter = $topFrameList[$topFrameSignature]
                $topFrameList[$topFrameSignature] = $counter+1
            }
            else
            {
                $topFrameList.Add($topFrameSignature, 1)
            }
        }
    }

    
    $frameList | Format-Table -AutoSize
}

Write-Host
Write-Host
Write-Host "Top frames found in threads with custom code across collections summed by thread id:"
Write-Host "This means the thread has been blocked across a collection"
#foreach ($key in $threadList.Keys) 
#{
#    if ($threadList[$key] -ne 1) 
#    {
#        Write-Host $key ": Count = " $threadList[$key]
#    }
#
#} #Format-Table -AutoSize
#Damiano: write the list with the count, sorted by count desc
foreach ($tuple in $threadList.GetEnumerator() | Sort Value -Descending)
{
    if ($tuple.Value -ne 1) 
    {
        Write-Host $tuple.Key ": Count = " $tuple.Value
    }
} #Format-Table -AutoSize

Write-Host
Write-Host
Write-Host "Top frames from frames with custom code - across collections:"
#$topFrameList | Format-Table -AutoSize
#Damiano: write the list with the count, sorted by count desc
foreach ($tuple in $topFrameList.GetEnumerator() | Sort Value -Descending)
{
    if ($tuple.Value -ne 1)
    {
        Write-Host $tuple.Key ": Count = " $tuple.Value
    }
}
