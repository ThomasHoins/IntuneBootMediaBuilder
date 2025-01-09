$MainForm = New-Object -TypeName System.Windows.Forms.Form
[System.Windows.Forms.Button]$btnCreate = $null
[System.Windows.Forms.TextBox]$TextBox1 = $null
[System.Windows.Forms.TextBox]$TextBox2 = $null
[System.Windows.Forms.TextBox]$TextBox3 = $null
[System.Windows.Forms.RadioButton]$rdImage = $null
[System.Windows.Forms.RadioButton]$rdUSB = $null
[System.Windows.Forms.Label]$lblTenantID = $null
[System.Windows.Forms.Label]$lblAppID = $null
[System.Windows.Forms.Label]$lblAppSecret = $null
[System.Windows.Forms.StatusStrip]$StatusStrip1 = $null
[System.Windows.Forms.ToolStripStatusLabel]$slblStatus = $null
[System.Windows.Forms.ToolStripStatusLabel]$ToolStripStatusLabel1 = $null
function InitializeComponent
{
$btnCreate = (New-Object -TypeName System.Windows.Forms.Button)
$TextBox1 = (New-Object -TypeName System.Windows.Forms.TextBox)
$TextBox2 = (New-Object -TypeName System.Windows.Forms.TextBox)
$TextBox3 = (New-Object -TypeName System.Windows.Forms.TextBox)
$rdImage = (New-Object -TypeName System.Windows.Forms.RadioButton)
$rdUSB = (New-Object -TypeName System.Windows.Forms.RadioButton)
$lblTenantID = (New-Object -TypeName System.Windows.Forms.Label)
$lblAppID = (New-Object -TypeName System.Windows.Forms.Label)
$lblAppSecret = (New-Object -TypeName System.Windows.Forms.Label)
$StatusStrip1 = (New-Object -TypeName System.Windows.Forms.StatusStrip)
$slblStatus = (New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel)
$ToolStripStatusLabel1 = (New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel)
$StatusStrip1.SuspendLayout()
$MainForm.SuspendLayout()
#
#btnCreate
#
$btnCreate.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]342,[System.Int32]159))
$btnCreate.Name = [System.String]'btnCreate'
$btnCreate.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]75,[System.Int32]23))
$btnCreate.TabIndex = [System.Int32]6
$btnCreate.Text = [System.String]'Create'
$btnCreate.UseVisualStyleBackColor = $true
#
#TextBox1
#
$TextBox1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]23,[System.Int32]25))
$TextBox1.Name = [System.String]'TextBox1'
$TextBox1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]394,[System.Int32]21))
$TextBox1.TabIndex = [System.Int32]1
#
#TextBox2
#
$TextBox2.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]23,[System.Int32]69))
$TextBox2.Name = [System.String]'TextBox2'
$TextBox2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]394,[System.Int32]21))
$TextBox2.TabIndex = [System.Int32]2
#
#TextBox3
#
$TextBox3.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]24,[System.Int32]112))
$TextBox3.Name = [System.String]'TextBox3'
$TextBox3.PasswordChar = [System.Char]'*'
$TextBox3.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]393,[System.Int32]21))
$TextBox3.TabIndex = [System.Int32]3
$TextBox3.Text = [System.String]'TEST122345'
#
#rdImage
#
$rdImage.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]24,[System.Int32]139))
$rdImage.Name = [System.String]'rdImage'
$rdImage.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]104,[System.Int32]24))
$rdImage.TabIndex = [System.Int32]4
$rdImage.TabStop = $true
$rdImage.Text = [System.String]'ISO Image'
$rdImage.UseVisualStyleBackColor = $true
#
#rdUSB
#
$rdUSB.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]24,[System.Int32]158))
$rdUSB.Name = [System.String]'rdUSB'
$rdUSB.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]104,[System.Int32]24))
$rdUSB.TabIndex = [System.Int32]5
$rdUSB.TabStop = $true
$rdUSB.Text = [System.String]'USB'
$rdUSB.UseVisualStyleBackColor = $true
#
#lblTenantID
#
$lblTenantID.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]24,[System.Int32]9))
$lblTenantID.Name = [System.String]'lblTenantID'
$lblTenantID.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]100,[System.Int32]13))
$lblTenantID.TabIndex = [System.Int32]0
$lblTenantID.Text = [System.String]'TenantID'
#
#lblAppID
#
$lblAppID.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]23,[System.Int32]49))
$lblAppID.Name = [System.String]'lblAppID'
$lblAppID.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]100,[System.Int32]17))
$lblAppID.TabIndex = [System.Int32]7
$lblAppID.Text = [System.String]'AppID'
#
#lblAppSecret
#
$lblAppSecret.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]24,[System.Int32]93))
$lblAppSecret.Name = [System.String]'lblAppSecret'
$lblAppSecret.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]100,[System.Int32]16))
$lblAppSecret.TabIndex = [System.Int32]8
$lblAppSecret.Text = [System.String]'App Secret'
#
#StatusStrip1
#
$StatusStrip1.Items.AddRange([System.Windows.Forms.ToolStripItem[]]@($slblStatus,$ToolStripStatusLabel1))
$StatusStrip1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0,[System.Int32]193))
$StatusStrip1.Name = [System.String]'StatusStrip1'
$StatusStrip1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]443,[System.Int32]22))
$StatusStrip1.TabIndex = [System.Int32]9
$StatusStrip1.Text = [System.String]'StatusStrip1'
#
#slblStatus
#
$slblStatus.Name = [System.String]'slblStatus'
$slblStatus.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]0,[System.Int32]17))
$slblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
#
#ToolStripStatusLabel1
#
$ToolStripStatusLabel1.Name = [System.String]'ToolStripStatusLabel1'
$ToolStripStatusLabel1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]0,[System.Int32]17))
$ToolStripStatusLabel1.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
#
#MainForm
#
$MainForm.ClientSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]443,[System.Int32]215))
$MainForm.Controls.Add($StatusStrip1)
$MainForm.Controls.Add($lblAppSecret)
$MainForm.Controls.Add($lblAppID)
$MainForm.Controls.Add($lblTenantID)
$MainForm.Controls.Add($rdUSB)
$MainForm.Controls.Add($rdImage)
$MainForm.Controls.Add($TextBox3)
$MainForm.Controls.Add($TextBox2)
$MainForm.Controls.Add($TextBox1)
$MainForm.Controls.Add($btnCreate)
$MainForm.MaximizeBox = $false
$MainForm.MinimizeBox = $false
$MainForm.Name = [System.String]'MainForm'
$MainForm.Text = [System.String]'Intune Boot Media Builder'
$StatusStrip1.ResumeLayout($false)
$StatusStrip1.PerformLayout()
$MainForm.ResumeLayout($false)
$MainForm.PerformLayout()
Add-Member -InputObject $MainForm -Name btnCreate -Value $btnCreate -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name TextBox1 -Value $TextBox1 -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name TextBox2 -Value $TextBox2 -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name TextBox3 -Value $TextBox3 -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name rdImage -Value $rdImage -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name rdUSB -Value $rdUSB -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name lblTenantID -Value $lblTenantID -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name lblAppID -Value $lblAppID -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name lblAppSecret -Value $lblAppSecret -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name StatusStrip1 -Value $StatusStrip1 -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name slblStatus -Value $slblStatus -MemberType NoteProperty
Add-Member -InputObject $MainForm -Name ToolStripStatusLabel1 -Value $ToolStripStatusLabel1 -MemberType NoteProperty
}
. InitializeComponent
