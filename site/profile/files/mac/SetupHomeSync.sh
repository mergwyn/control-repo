#/bin/bash
cd ${HOME}

ensureDir()
{
	[[ -d ${1} ]] || mkdir -p ${1}
}
ensureDir ${HOME}/.unison 
for file in Home.prf Preferences.prf common.prf default.prf
do
	[[ -f ${HOME}/.unison/${file} ]] && rm ${HOME}/.unison/${file}
	ln -s /usr/local/share/${file} ${HOME}/.unison/${file}
done

ensureDir ${HOME}/Library/LaunchAgents

for file in com.theclarkhome.prefsync.plist com.theclarkhome.logoutwatcher.plist
do
	[[ -f ${HOME}/Library/LaunchAgents/${file} ]] && rm ${HOME}/Library/LaunchAgents/${file}
	ln -s /usr/local/share/${file} ${HOME}/Library/LaunchAgents/${file}
	plutil -lint ${HOME}/Library/LaunchAgents/${file} && {
		launchctl unload ${HOME}/Library/LaunchAgents/${file}
		launchctl load ${HOME}/Library/LaunchAgents/${file}
	}
done
