New-NetFirewallRule `
  -DisplayName "simple-go-web-app" `
  -Direction Inbound `
  -Enabled True `
  –Protocol TCP `
  -LocalPort <%= p("port") %>
