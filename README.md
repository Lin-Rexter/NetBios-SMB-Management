# Management_NetBios[SMB]_TCP[139、445]、UDP[137、138]

## 使用: 關閉或開啟TCP 139、445與UDP 137、138，檢查任一連接埠狀態。

### Language Version: 中文、English
________________________________________________________________________________________________________________

<dl>
	<dt>關閉NetBios步驟</dt>
	``<dd>參考: https://github.com/hvs-consulting/disable-netbios/blob/main/disable_netbios.ps1</dd>``
</dl>

<dl>
	<dt>關閉[TCP]139 Port 步驟</dt>
	<dd>1. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Control\Lsa當中的restrictanonymous值改成2</dd>
	<dd>2. 關閉lmhosts服務，並設置成停用狀態。</dd>
	<dd>3. 關閉netbios服務，並設置成停用狀態。</dd>
	<dd>4. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters當中的AutoShareServer值改成0</dd>
	<dd>5. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters當中的AutoShareWks值改成0</dd>
	<dd>6. 創建防火牆阻擋入站Port 139規則</dd>
</dl>

<dl>
	<dt>關閉[TCP]445 Port 步驟</dt>
	<dd>1. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters當中的SMBDeviceEnabled值改成0</dd>
	<dd>2. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters當中的TransportBindName值清空</dd>
	<dd>3. 關閉lanmanserver服務，並設置成停用狀態。</dd>
	<dd>4. 創建防火牆阻擋入站Port 445規則</dd>
</dl>

<dl>
	<dt>關閉[UDP]137 Port 步驟</dt>
	<dd>1. 創建防火牆阻擋入站Port 137規則</dd>
</dl>

<dl>
	<dt>關閉[UDP]138 Port 步驟</dt>
	<dd>1. 創建防火牆阻擋入站Port 138規則</dd>
</dl>
