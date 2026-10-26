param(
    [int]$Port = 8000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

# In-memory database
$script:customers = @(
    [ordered]@{ id = 1; name = "Suresh Sharma"; phone = "98765 43210"; balance = 1450; balance_paise = 145000; type = "udhaar" },
    [ordered]@{ id = 2; name = "Ramesh Kumar"; phone = "88877 66554"; balance = 3600; balance_paise = 360000; type = "udhaar" },
    [ordered]@{ id = 3; name = "Pooja Verma"; phone = "91234 56789"; balance = -890; balance_paise = -89000; type = "jama" },
    [ordered]@{ id = 4; name = "Vikram Singh"; phone = "99887 76655"; balance = 5200; balance_paise = 520000; type = "udhaar" },
    [ordered]@{ id = 5; name = "Aisha Khan"; phone = "87654 32109"; balance = 0; balance_paise = 0; type = "settled" }
)

$script:recentActivity = @(
    [ordered]@{ id = 1; name = "Ramesh Kumar"; type = "udhaar"; amount = 1450; time = "10:30 AM" },
    [ordered]@{ id = 2; name = "Suresh Sharma"; type = "jama"; amount = 800; time = "11:15 AM" },
    [ordered]@{ id = 3; name = "Cash Sale"; type = "cash"; amount = 250; time = "12:00 PM" }
)

$script:nextCustomerId = 6

try {
    $listener.Start()
    $lanIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    if (-not $lanIp) { $lanIp = "127.0.0.1" }
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host " Munim Ji AI Backend Server Running!             " -ForegroundColor Green
    Write-Host " Local URL   : http://localhost:$Port/           " -ForegroundColor Yellow
    Write-Host " Network URL : http://$($lanIp):$Port/          " -ForegroundColor Yellow
    Write-Host " Press Ctrl+C in terminal to stop.               " -ForegroundColor Gray
    Write-Host "=================================================" -ForegroundColor Cyan

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization")
        $response.ContentType = "application/json; charset=utf-8"

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $urlPath = $request.Url.AbsolutePath
        $method = $request.HttpMethod
        $jsonResp = "{}"

        # Read Request Body if entity present
        $bodyText = ""
        if ($request.HasEntityBody) {
            $reader = [System.IO.StreamReader]::new($request.InputStream, $request.ContentEncoding)
            $bodyText = $reader.ReadToEnd()
            $reader.Close()
        }

        # ------------------- 1. AUTH -------------------
        if ($urlPath -eq "/api/auth/send-otp" -and $method -eq "POST") {
            $jsonResp = '{"success": true, "message": "OTP 123456 sent successfully", "otp": "123456", "test_otp": "123456"}'
        }
        elseif ($urlPath -eq "/api/auth/verify-otp" -and $method -eq "POST") {
            $jsonResp = '{"success": true, "token": "jwt_token_munim_ji_active_session", "user": {"phone": "9876543210", "name": "Sharma Kirana Store"}}'
        }

        # ------------------- 2. CHAT & VOICE -------------------
        elseif ($urlPath -eq "/api/chat" -and $method -eq "POST") {
            $msgLower = $bodyText.ToLower()
            $reply = "Namaste Ji! Main aapka AI Munim. Aap mujhse sale, udhaar, customer balances, ya hisaab-kitaab ke baare mein pooch sakte hain."

            if ($msgLower -match "sale" -or $msgLower -match "aaj") {
                $reply = "Aaj ki Total Sale: ₹14,250 (Jama: ₹8,500 | Udhaar: ₹5,750)."
            }
            elseif ($msgLower -match "udhaar" -or $msgLower -match "baaki") {
                $reply = "Ramesh Kumar par ₹1,450 ka udhaar baki hai. Kul 4 customers par ₹9,360 baki hai."
            }
            elseif ($msgLower -match "jama") {
                $reply = "Payment Jama darj kar liya gaya hai. Khata update ho chuka hai."
            }
            elseif ($msgLower -match "cash") {
                $reply = "Cash Sale safalta se darj kar li gayi hai."
            }
            elseif ($msgLower -match "report" -or $msgLower -match "summary") {
                $reply = "Is mahine ki Total Sale ₹3,45,000 hui hai. Overall Udhaar recovery 84% hai."
            }

            $jsonResp = [ordered]@{
                success = $true
                reply = $reply
            } | ConvertTo-Json -Compress
        }
        elseif ($urlPath -eq "/api/voice" -and $method -eq "POST") {
            $jsonResp = '{"success": true, "transcript": "Ramesh 500 udhaar", "reply": "Ramesh Kumar par ₹500 udhaar darj ho gaya."}'
        }

        # ------------------- 3. CUSTOMERS -------------------
        elseif ($urlPath -eq "/api/customers" -and $method -eq "GET") {
            $jsonResp = [ordered]@{
                customers = $script:customers
                total = $script:customers.Count
            } | ConvertTo-Json -Depth 3 -Compress
        }
        elseif ($urlPath -eq "/api/customers" -and $method -eq "POST") {
            $parsed = @{}
            try { $parsed = $bodyText | ConvertFrom-Json } catch {}
            $newName = if ($parsed.name) { $parsed.name } else { "Naya Grahak" }
            $newPhone = if ($parsed.phone) { $parsed.phone } else { "" }

            $newCust = [ordered]@{
                id = $script:nextCustomerId++
                name = $newName
                phone = $newPhone
                balance = 0
                balance_paise = 0
                type = "settled"
            }
            $script:customers += $newCust

            $jsonResp = [ordered]@{
                id = $newCust.id
                name = $newCust.name
                phone = $newCust.phone
                balance = 0
                balance_paise = 0
                message = "Customer successfully add ho gaya"
            } | ConvertTo-Json -Depth 3 -Compress
        }
        elseif ($urlPath -like "/api/customers/*/ledger" -and $method -eq "GET") {
            $jsonResp = [ordered]@{
                balance_paise = 145000
                entries = @(
                    [ordered]@{ id = 101; date = "2026-10-18T10:30:00Z"; amount = 500; amount_paise = 50000; transaction_type = "Debit"; item_desc = "Aata 10kg & Chini 2kg" },
                    [ordered]@{ id = 102; date = "2026-10-15T16:15:00Z"; amount = 950; amount_paise = 95000; transaction_type = "Debit"; item_desc = "Refined Oil 5L" },
                    [ordered]@{ id = 103; date = "2026-10-10T14:00:00Z"; amount = 1000; amount_paise = 100000; transaction_type = "Credit"; item_desc = "UPI Payment received" }
                )
            } | ConvertTo-Json -Depth 3 -Compress
        }
        elseif ($urlPath -eq "/api/customers/merge" -and $method -eq "POST") {
            $jsonResp = '{"success": true, "message": "Customers merged successfully"}'
        }

        # ------------------- 4. SUMMARY & REPORTS -------------------
        elseif ($urlPath -eq "/api/summary" -and $method -eq "GET") {
            $jsonResp = [ordered]@{
                todaySales = 14250
                totalJama = 8500
                totalUdhaar = 5750
                customerCount = $script:customers.Count
                udhaar_display = "₹5,750"
                jama_display = "₹8,500"
                cash_sale_display = "₹14,250"
                jama_count = 14
                udhaar_count = 8
                cash_count = 32
                jama_paise = 850000
                udhaar_paise = 575000
                cash_sale_paise = 1425000
                recent_activity = $script:recentActivity
            } | ConvertTo-Json -Depth 3 -Compress
        }
        elseif ($urlPath -eq "/api/export" -and $method -eq "GET") {
            $jsonResp = '{"success": true, "url": "/api/export/munim_ji_report.xlsx"}'
        }
        elseif ($urlPath -eq "/api/audit" -and $method -eq "GET") {
            $jsonResp = '{"success": true, "audit": []}'
        }

        # ------------------- 5. TRANSACTIONS & ACCOUNT -------------------
        elseif ($urlPath -like "/api/transactions/*" -and ($method -eq "PATCH" -or $method -eq "DELETE")) {
            $jsonResp = '{"success": true, "message": "Transaction updated successfully"}'
        }
        elseif ($urlPath -eq "/api/account" -and $method -eq "DELETE") {
            $jsonResp = '{"success": true, "message": "Account reset successfully"}'
        }
        else {
            $jsonResp = '{"status": "online", "service": "Munim Ji AI Backend API", "version": "1.0"}'
        }

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonResp)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Flush()
        $response.Close()
    }
} catch {
    Write-Host "Backend Server error: $_" -ForegroundColor Red
} finally {
    if ($listener) { $listener.Stop() }
}
