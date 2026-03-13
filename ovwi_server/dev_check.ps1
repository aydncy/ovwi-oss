Write-Host "=================================" -ForegroundColor Cyan
Write-Host "OVWI PLATFORM TEST SUITE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$urls = @(
"http://localhost:8081/health",
"http://localhost:8081/api/v1/dashboard/stats",
"http://localhost:8081/api/v1/analytics/summary",
"http://localhost:8081/api/v1/gateway/patients",
"http://localhost:8081/api/v1/gateway/doctors",
"http://localhost:8081/api/v1/gateway/appointments"
)

foreach ($url in $urls) {

    Write-Host "`n---------------------------------" -ForegroundColor DarkGray
    Write-Host "TEST:" $url -ForegroundColor Yellow

    $start = Get-Date

    try {

        $response = Invoke-WebRequest -Uri $url -UseBasicParsing

        $end = Get-Date
        $latency = ($end - $start).TotalMilliseconds

        Write-Host "STATUS:" $response.StatusCode -ForegroundColor Green
        Write-Host "LATENCY:" "$latency ms" -ForegroundColor Cyan
        Write-Host "BODY:" -ForegroundColor White
        Write-Host $response.Content

    } catch {

        Write-Host "FAILED:" $url -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

    }

}

Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
