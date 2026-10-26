param(
    [int]$Port = 8090,
    [string]$Path = ""
)

if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = Join-Path $PSScriptRoot "build\web"
}

Write-Host "Script path: $PSScriptRoot" -ForegroundColor Gray
Write-Host "Build path : $Path" -ForegroundColor Gray

if (-not (Test-Path $Path)) {
    Write-Host "ERROR: Build folder nahi mila: $Path" -ForegroundColor Red
    Write-Host "Pehle 'flutter build web' chalao." -ForegroundColor Yellow
    exit 1
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".wasm" = "application/wasm"
    ".ttf"  = "font/ttf"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}

try {
    $listener.Start()
    Write-Host "HTTP Server listening on http://localhost:$Port/" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray

    $basePath = (Resolve-Path $Path).Path
    $basePathWithSep = $basePath
    if (-not $basePathWithSep.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $basePathWithSep += [System.IO.Path]::DirectorySeparatorChar
    }

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $urlPath = $request.Url.AbsolutePath
            if ($urlPath -eq "/") { $urlPath = "/index.html" }

            $filePath = Join-Path $basePath $urlPath.TrimStart('/')
            $filePath = [System.IO.Path]::GetFullPath($filePath)

            if (-not ($filePath -eq $basePath -or $filePath.StartsWith($basePathWithSep))) {
                $filePath = Join-Path $basePath "index.html"
            }
            if (-not (Test-Path $filePath -PathType Leaf)) {
                $filePath = Join-Path $basePath "index.html"
            }

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $contentType = "application/octet-stream"
                if ($mimeTypes.ContainsKey($ext)) {
                    $contentType = $mimeTypes[$ext]
                }
                $response.ContentType = $contentType
                $response.Headers.Add("Access-Control-Allow-Origin", "*")
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.OutputStream.Flush()
            } else {
                $response.StatusCode = 404
            }
            $response.Close()
        } catch {
            Write-Host "Request error: $_" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "START ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Port $Port probably in use. Try another port." -ForegroundColor Yellow
} finally {
    if ($listener) {
        try { $listener.Close() } catch { }
    }
}