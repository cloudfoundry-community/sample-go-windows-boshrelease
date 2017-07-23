New-NetFirewallRule -LocalPort <%= p("port") %> -Protocol TCP `
  -Direction Inbound `
  -Name simple-go-web-app -DisplayName simple-go-web-app
