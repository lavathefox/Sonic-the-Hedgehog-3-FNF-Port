player = 'tails'
skidparticlesnumber = 0
skidparticlesperframetimer = 0
skidparticlesperframelimit = 4
skidparticleremovetimer = 25
------ sorry aNormalPerson for using your code :( -------------

function onUpdate()

	-- -- -- -- -- -- -- -- -- -- -- -- -- S K I D   P A R T I C L E S -- -- -- -- -- -- -- -- -- -- -- -- --

	if skidparticlesperframetimer < skidparticlesperframelimit then
		skidparticlesperframetimer = skidparticlesperframetimer + 1
	end
	if getProperty(player..'.animation.curAnim.name') == 'skidding' and skidparticlesperframetimer >= skidparticlesperframelimit or
	getProperty(player..'.animation.curAnim.name') == 'standupA' and skidparticlesperframetimer >= skidparticlesperframelimit
	then
		makeAnimatedLuaSprite('skidparticles'..skidparticlesnumber, 'particles/skidparticles', getProperty(player..'.x')+20, getProperty(player..'.y')+36)
		addAnimationByPrefix('skidparticles'..skidparticlesnumber, 'skidparticles', 'skidparticles', 12, false)
		addLuaSprite('skidparticles'..skidparticlesnumber, true)
		setObjectOrder('skidparticles'..skidparticlesnumber, getObjectOrder(player)+1)

		skidparticlesnumber = skidparticlesnumber+1
		skidparticleremovetimer = 0
		skidparticlesperframetimer = 0
	end
	if skidparticleremovetimer < 25 then
		skidparticleremovetimer = skidparticleremovetimer+1
	end
	if skidparticleremovetimer == 24 then
		for i=0,skidparticlesnumber do
			removeLuaSprite('skidparticles'..i)
			skidparticlesnumber = 0
		end
	end

	-- -- -- -- -- -- -- -- -- -- -- -- -- S P I N D A S H   P A R T I C L E S -- -- -- -- -- -- -- -- -- -- -- -- --

	if getProperty(player..'.animation.curAnim.name') == 'spindash' and not luaSpriteExists('spindashdust') then
		makeAnimatedLuaSprite('spindashdust', 'particles/spindashdust', getProperty(player..'.x'), getProperty(player..'.y'))
		addAnimationByPrefix('spindashdust', 'spindashdust', 'spindashdust', 24, true)
		addLuaSprite('spindashdust')
		setObjectOrder('spindashdust', getObjectOrder(player)+1)

		if getProperty(player..'.flipX') then
			setProperty('spindashdust.x', getProperty(player..'.x')+16)
			setProperty('spindashdust.flipX', true)
		elseif not getProperty(player..'.flipX') then
			setProperty('spindashdust.x', getProperty(player..'.x')-16)
			setProperty('spindashdust.flipX', false)
		end
	end
	if luaSpriteExists('spindashdust') and getProperty(player..'.animation.curAnim.name') ~= 'spindash' then
		removeLuaSprite('spindashdust')
	end
end
