$root = $PSScriptRoot
$port = 8080
$url  = "http://localhost:$port/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($url)
$listener.Start()

Write-Host ""
Write-Host "  Serving at http://localhost:$port" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Games:" -ForegroundColor Green
Write-Host "    http://localhost:$port/shooter.html"
Write-Host "    http://localhost:$port/tictactoe.html"
Write-Host ""
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

$mimeTypes = @{
  '.html' = 'text/html; charset=utf-8'
  '.css'  = 'text/css'
  '.js'   = 'application/javascript'
  '.png'  = 'image/png'
  '.ico'  = 'image/x-icon'
}

try {
  while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response

    $path = $req.Url.LocalPath.TrimStart('/')
    if ($path -eq '' -or $path -eq '/') { $path = 'index.html' }
    $file = Join-Path $root $path

    if (Test-Path $file -PathType Leaf) {
      $ext  = [System.IO.Path]::GetExtension($file)
      $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $resp.ContentType   = $mime
      $resp.ContentLength64 = $bytes.Length
      $resp.StatusCode    = 200
      $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      Write-Host "  200  $($req.Url.LocalPath)" -ForegroundColor DarkGray
    } else {
      # Auto-index for root
      if ($req.Url.LocalPath -eq '/') {
        $html = "<html><body style='font:16px monospace;background:#0d0d14;color:#4ecca3;padding:2rem'>"
        $html += "<h2>Games</h2><ul>"
        Get-ChildItem $root -Filter '*.html' | ForEach-Object {
          $html += "<li><a href='/$($_.Name)' style='color:#ffe66d'>$($_.Name)</a></li>"
        }
        $html += "</ul></body></html>"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
        $resp.ContentType     = 'text/html; charset=utf-8'
        $resp.ContentLength64 = $bytes.Length
        $resp.StatusCode      = 200
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $resp.StatusCode = 404
        Write-Host "  404  $($req.Url.LocalPath)" -ForegroundColor Red
      }
    }
    $resp.OutputStream.Close()
  }
} finally {
  $listener.Stop()
}
