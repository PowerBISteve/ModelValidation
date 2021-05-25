Import-Module Microsoft.PowerShell.Utility
Add-Type -AssemblyName PresentationFramework

$serverVal = $args[0]
$databaseIdVal =  $args[1]


$storevals1 = 'C:\Temp\valfile.txt'
$storevals2 = 'C:\Temp\valfolder.txt'

$initialDirectory = Get-Content $storevals1
$pathToOutputFile  = Get-Content $storevals2



function Select-Folder() {
  $object = New-Object -comObject Shell.Application

  $folder = $object.BrowseForFolder(0, "Select a Folder for the output report", 0)
  if ($folder -ne $null) {
    $folder.self.Path
  }
}


Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    #$foldername = New-Object System.Windows.Forms.FolderBrowserDialog   
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.FileName

}



Function Validate-DAX($server,$databaseId,[string]$vcsvfile)
{
  



    $data = @()
    $vals = Import-Csv $vcsvfile
    $headers = $vals | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'  | Where-Object { $_ –ne "Value" -and $_ –ne "Measure"-and $_ –ne "ID" }

    
    foreach ($row in $vals){

        $q = -join( 'Calculate([', $row.'Measure', ']')  

        foreach($head in $headers){

        

          if( $row.$head -eq "")
              {$qpart =  -join ('ALL(', $head, ')')} 
          else 
              {$qpart =  -join ($head, ' = "', $row.$head, '"' )}

          $q = -join( $q," , ", $qpart)
        }   

        $dax = -Join($q, ')' )
        $queryv = -Join( 'EVALUATE ROW("m",' , $dax, ')')
        $validation = $row.'Value' -as [double]

        $output = ''
        [xml]$output = Invoke-AsCmd -Server:$server -Database:$databaseId  -Query:$queryv
        $queryval = $output.return.root.row.FirstChild.'#text' -as [double]

 

        $diff = if($validation -eq 0 -and $queryval -ne 0) {1} else {($queryval - $validation) / $validation }
        $fail = [Math]::Abs($diff) -gt 0.0001
 
        $data =   $data + @(
           [pscustomobject]@{Validation= $validation;Model=$queryval;Fail =$fail; ID = $row.'ID'; MeasureSent = $queryv}
           )
    }
 
 return $data
}


Function OutPutFile([string]$basepath)
{
$n = 0
$fn = $basepath
$valname = '\ValidationOutput.csv'
$pth = $fn + $valname
$break = 0 
DO
{
if($newfile = Test-Path -Path  $pth)
    {$n += 1
    $pth = $fn + $valname + $n + '.csv'}
else
    {$break = 1}

} Until ($break -eq 1)
return $pth
}

# Loading external assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Creation of the components.
$SelectValidation = New-Object System.Windows.Forms.Form
$input_text = New-Object System.Windows.Forms.TextBox
$input_text2 = New-Object System.Windows.Forms.TextBox
$label = New-Object System.Windows.Forms.Label
$label2 = New-Object System.Windows.Forms.Label
$validate_file = New-Object System.Windows.Forms.Button
$validate_output = New-Object System.Windows.Forms.Button
$validate_action  = New-Object System.Windows.Forms.Button

$SelectValidation.ClientSize = New-Object System.Drawing.Size(376, 250)
$iconBase64      = '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'
$iconBytes       = [Convert]::FromBase64String($iconBase64)
$stream          = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$stream.Write($iconBytes, 0, $iconBytes.Length);
$iconImage       = [System.Drawing.Image]::FromStream($stream, $true)
$SelectValidation.Icon       = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())

$SelectValidation.MaximizeBox = $false
$SelectValidation.MinimizeBox = $false
$SelectValidation.Name = "SelectValidation"
$SelectValidation.Text = "Validation Report"

$validate_file.Location = New-Object System.Drawing.Point(325, 60)
$validate_file.Name = "validate_file"
$validate_file.Size = New-Object System.Drawing.Size(30, 20)
$validate_file.TabIndex = 1
$validate_file.Text = "..."
$validate_file.UseVisualStyleBackColor = $false
$SelectValidation.Controls.Add($validate_file)

$validate_output.Location = New-Object System.Drawing.Point(325, 150)
$validate_output.Name = "validate_output"
$validate_output.Size = New-Object System.Drawing.Size(30, 20)
$validate_output.TabIndex = 1
$validate_output.Text = "..."
$validate_output.UseVisualStyleBackColor = $false
$SelectValidation.Controls.Add($validate_output)


$validate_action.Location = New-Object System.Drawing.Point(143, 200)
$validate_action.Name = "validate_file"
$validate_action.Size = New-Object System.Drawing.Size(90, 40)
$validate_action.TabIndex = 1
$validate_action.Text = "Validate Model"
#$validate_action.BackColor = "White"
#$validate_action.UseVisualStyleBackColor = $true
$SelectValidation.Controls.Add($validate_action)

$pathn = $initialDirectory
$input_text.AutoSize = $true
$input_text.Location = New-Object System.Drawing.Point(20, 50)
$input_text.Name = "input_text"
$input_text.Size = New-Object System.Drawing.Size(300, 40)
#$input_text.TabIndex = 5
$input_text.Text = $pathn 
$input_text.BackColor = "White"
$input_text.BorderStyle = 1
$input_text.Enabled = $false
$input_text.WordWrap = $true
$input_text.Multiline = $true
$input_text.AcceptsTab = $true
$SelectValidation.Controls.Add($input_text)

$patho = $pathToOutputFile
$input_text2.AutoSize = $true
$input_text2.Location = New-Object System.Drawing.Point(20, 140)
$input_text2.Name = "input_text2"
$input_text2.Size = New-Object System.Drawing.Size(300, 40)
#$input_text2.TabIndex = 5
$input_text2.Text = $patho
$input_text2.BackColor = "White"
$input_text2.BorderStyle = 1
$input_text2.Enabled = $false
$input_text2.WordWrap = $true
$input_text2.Multiline = $true
$input_text2.AcceptsTab = $true
$SelectValidation.Controls.Add($input_text2)


$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Name = "label"
$label.Size = New-Object System.Drawing.Size(300, 30)
$label.TabIndex = 5
$label.Text = "Choose the validation CSV for your report"
$label.Enabled = $false
$SelectValidation.Controls.Add($label)

$label2.AutoSize = $true
$label2.Location = New-Object System.Drawing.Point(20, 110)
$label2.Name = "label"
$label2.Size = New-Object System.Drawing.Size(300, 30)
$label2.TabIndex = 5
$label2.Text = "Choose the folder for your output report"
$label2.Enabled = $false
$SelectValidation.Controls.Add($label2)


$validate_file.Add_Click( { 
    $pathn = Get-FileName
    $input_text.Text = $pathn 
})

$validate_output.Add_Click( { 
    $patho  = Select-Folder 
    $input_text2.Text = $patho 
})


$validate_action.Add_Click( { 
    $validation = Validate-DAX $serverVal $databaseIdVal $input_text.Text
    $failures = ($validation | Where-Object { $_.Fail –eq "True" })
    $xx = ($failures |measure).Count
    $result =  [System.Windows.MessageBox]::Show('You completed with' + $xx + ' Errors. Export Results?', 'Output', 'YesNo')
    if ($result -eq 'Yes') { 
    [System.Windows.MessageBox]::$failures
    Out-File -FilePath $storevals1 -InputObject  $input_text.Text -Force

    $outputfilename = OutPutFile $input_text2.Text
    $validation | Export-CSV $outputfilename -NoTypeInformation -Force
    Out-File -FilePath $storevals2 -InputObject  $input_text2.Text -Force
    $SelectValidation.Close()
    }
   else
   { $SelectValidation.Close()}
})




function OnFormClosing_SelectValidation{ 
	($_).Cancel= $False
}

$SelectValidation.Add_FormClosing( { OnFormClosing_SelectValidation} )

$SelectValidation.Add_Shown({$SelectValidation.Activate()})
$ModalResult=[system.windows.forms.application]::run($SelectValidation) #.ShowDialog()

# Release the Form
$SelectValidation.Dispose()

