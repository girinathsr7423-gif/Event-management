# ==============================================================================
# Lightweight HTTP Server for College Event Management System
# Serves Web Portal & Visual Analytics on http://localhost:8080/
# ==============================================================================

$port = 8080
$prefix = "http://localhost:$port/"
$webRoot = $PSScriptRoot
$visRoot = Join-Path (Split-Path $webRoot -Parent) "python\visualizations"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "[+] Web Server is running on $prefix"
    Write-Host "[+] Press Ctrl+C in terminal to stop the server."
} catch {
    Write-Error "[-] Failed to start HTTP listener on port ${port} - $_"
    exit 1
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.AbsolutePath

        if ($path -eq "/" -or $path -eq "/index.html") {
            $filePath = Join-Path $webRoot "index.html"
            $contentType = "text/html; charset=utf-8"
        } elseif ($path.StartsWith("/visualizations/")) {
            $fileName = $path.Substring("/visualizations/".Length)
            $filePath = Join-Path $visRoot $fileName
            $contentType = "image/svg+xml"
        } else {
            $filePath = Join-Path $webRoot ($path.TrimStart('/'))
            if ($path.EndsWith(".svg")) { $contentType = "image/svg+xml" }
            elseif ($path.EndsWith(".css")) { $contentType = "text/css" }
            elseif ($path.EndsWith(".js")) { $contentType = "application/javascript" }
            elseif ($path.EndsWith(".json")) { $contentType = "application/json" }
            else { $contentType = "text/html; charset=utf-8" }
        }

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.Close()
    } catch {
        # Handle client connection drops gracefully
    }
}
