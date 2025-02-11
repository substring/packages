pkgrel++
source+='aliases.sh'
source+='groovyarcade-logo.png::https://gitlab.com/groovyarcade/branding/-/raw/main/discord/logo-discord-round.png?ref_type=heads&inline=false'
source+='asciilogo.txt'
files+=    ["etc/profile.d/aliases.sh"]="aliases.sh:644:0:0"
files+=    ["usr/share/pixmaps/groovyarcade-logo.png"]="groovyarcade-logo.png:644:0:0"
files+=    ["usr/share/neofetch/asciilogo.txt"]="asciilogo.txt:644:0:0"
