# Sprite class to mimic pygame.Sprite behaviour
# 2012 Florian Piesche, florian@yellowkeycard.net
# License: http://creativecommons.org/licenses/by-sa/3.0/

# SpriteSheet format: same-size frames; animation frames on horizontal axis.
# call initSize((x, y)) once to set initial values for current frame, etc

import UnityEngine

class ykcSprite(MonoBehaviour):

	public SpriteRect as Rect = Rect(0, 0, 0, 0)
	public CollisionRect as Rect = Rect(0, 0, 0, 0)
	public SpriteTexCoords as Rect = Rect(0, 0, 0, 0)
	public SpriteSheet as Texture2D
	public CollisionTex as Texture2D
	public NumSprites as (int) = (0, 0)
	public SpriteOffset as (int) = (0, 0)
	public SpriteSize as (int) = (0, 0)
	public CurrentSprite as (int) = (0, 0)
	public AnimationTimer as int = 0
	public AnimationSpeed as int = 0
	public AnimationFrames as int = 0
	public AnimationLoop as bool = false
	public AnimationActive as bool = false
	public AnimationDirection as int = 0
	public AnimationPingpong as bool = false
	public Visible as bool = true
	public ManualDraw as bool = false
	public Alpha as single = 1.0F


	def InitSize (size as (int), collisionSize as (int)):
		self.SpriteSize = size
		self.SpriteRect = Rect(self.SpriteRect.x, self.SpriteRect.y, size[0], size[1])
		self.NumSprites = (self.SpriteSheet.width / size[0], self.SpriteSheet.height / size[1])
		self.SpriteTexCoords = Rect(0, 0, size[0], size[1])
		self.SetFrame((0,0))
		self.CollisionRect.width = collisionSize[0]
		self.CollisionRect.height = collisionSize[1]
		self.UpdateCollisionTex()
		self.AnimationActive = false
		self.Visible = true
		self.ManualDraw = false


	def UpdateCollisionTex ():
		# update self.CollisionTex with an 8bit representation of CurrentSprite's alpha channel
		self.CollisionTex = Texture2D(self.SpriteSheet.width, self.SpriteSheet.height, TextureFormat.Alpha8, false)
		self.CollisionTex.SetPixels(self.SpriteSheet.GetPixels(0, 0, self.SpriteSize[0], self.SpriteSize[1], 0))
		self.CollisionTex.Apply()


	def SetPosition (position as (int), center as bool):
		# offset position by half sprite size to center
		if center == true:
			position[0] -= self.SpriteRect.width / 2
			position[1] -= self.SpriteRect.width / 2
		# place sprite at (int) pixel coordinates
		self.SpriteRect = Rect(position[0], position[1], self.SpriteRect.width, self.SpriteRect.height)
		self.CollisionRect = Rect(position[0] + self.SpriteRect.width, position[1] + self.SpriteRect.height, self.CollisionRect.width, self.CollisionRect.height)


	def Scale (factor as (single), center as bool):
		# scale sprite by factor. Keep centered if center == true.
		self.SetSize((Mathf.RoundToInt(self.SpriteRect.width * factor[0]), Mathf.RoundToInt(self.SpriteRect.height * factor[1])), center)


	def SetSize (newSize as (int), center as bool):
		# set sprite size to newSize. Keep centered if center == true.
		if center == true:
			posOffset = ((self.SpriteRect.x - newSize[0]) / 2, (self.SpriteRect.y - newSize[1]) / 2)
			self.SpriteRect.x += posOffset[0]
			self.SpriteRect.y += posOffset[1]
			self.CollisionRect.x += posOffset[0]
			self.CollisionRect.y += posOffset[1]
		self.SpriteRect.Set(self.SpriteRect.x + posOffset[0], self.SpriteRect.y + posOffset[1], newSize[0], newSize[1])
		sizeFactor = (1.0F * self.SpriteRect.width / newSize[0], 1.0F * self.SpriteRect.height / newSize[1])
		self.CollisionRect.Set(self.CollisionRect.x + posOffset[0], self.CollisionRect.y + posOffset[1], self.CollisionRect.width * sizeFactor[0], self.CollisionRect.height * sizeFactor[1])
		return newSize, (self.CollisionRect.width, self.CollisionRect.height)


	def ResetSize ():
		self.SetSize(self.SpriteSize, true)
		return self.SpriteSize


	def SetFrame (spriteToSet as (int)):
		# change sprite to (int) offset. Can be called manually or via Animate(). Returns false on error, true on success.
		if spriteToSet[0] > self.NumSprites[0] or spriteToSet[1] > self.NumSprites[1]:
			Debug.Log("Sprite offset exceeds maximum! " + spriteToSet[0].ToString() + "," + spriteToSet[1].ToString() + " / numSprites: " + self.NumSprites[0].ToString() + "," + self.NumSprites[1].ToString())
			return false
		if spriteToSet[0] < 0 or spriteToSet[1] < 0:
			Debug.Log("Negative sprite offset given! Using absolute instead.")
			spriteToSet[0] = Mathf.Abs(spriteToSet[0])
			spriteToSet[1] = Mathf.Abs(spriteToSet[1])
		self.CurrentSprite = spriteToSet
		self.SpriteTexCoords = Rect((spriteToSet[0] * self.SpriteSize[0]) / (self.SpriteSheet.width * 1.0F), (spriteToSet[1] * self.SpriteSize[1]) / (self.SpriteSheet.height * 1.0F), self.SpriteSize[0] / (self.SpriteSheet.width * 1.0F), self.SpriteSize[1] / (self.SpriteSheet.height * 1.0F))
		return self.CurrentSprite


	def SetAnim (rowToSet as int, animSpeed as int, maxFrame as int, loop as bool, pingpong as bool, reverse as bool):
		# start animation from rowToSet, animSpeed ms per frame, end/loop after maxFrames.
		self.SetFrame((0, rowToSet))
		self.AnimationActive = true
		self.AnimationLoop = loop
		self.AnimationTimer = (Time.time * 1000) + animSpeed
		self.AnimationSpeed = animSpeed
		self.AnimationFrames = maxFrame - 1
		self.AnimationPingpong = pingpong
		if reverse == false:
			self.AnimationDirection = 1
		else:
			self.AnimationDirection = 0


	def GetNumFrames ():
		# supplementary function for Animate() to find number of frames in spritesheet
		return (self.SpriteSheet.width / self.SpriteSize[0])


	def Draw ():
		# draw sprite. Can be called manually but is also automatically run from OnGUI().
		# Note that there is no way to control draw order other than by manual drawing.
		if self.AnimationActive == true:
			Animate()
		if self.Visible == true:
			GUI.color.a = self.Alpha
			GUI.DrawTextureWithTexCoords(self.SpriteRect, self.SpriteSheet, self.SpriteTexCoords, true)
			GUI.color.a = 1.0


	def CollideCheckRect (collider as Rect, PixelPerfect as bool):
		# check collision between self.SpriteRect and collider; returns first collision point
		for yCheck in range(collider.y, collider.y + collider.height):
			for xCheck in range(collider.x, collider.x + collider.width):
				if self.CollisionRect.Contains(Vector2(xCheck, yCheck)):
					return (xCheck, yCheck)
		if PixelPerfect:
			Debug.Log("NYI: pixel-perfect ykcSprite/Rect collision")

		return false

	def CollideCheckSprite (collider as ykcSprite, PixelPerfect as bool):
		rectCollide = false
		collisionPoint = null
		# check collision between self.SpriteRect and collider.SpriteRect, returns first collision point
		for yCheck in range(collider.CollisionRect.y, collider.CollisionRect.y + collider.CollisionRect.height):
			for xCheck in range(collider.CollisionRect.x, collider.CollisionRect.x + collider.CollisionRect.width):
				if self.CollisionRect.Contains(Vector2(xCheck, yCheck)):
					collisionPoint = (xCheck, yCheck)
					rectCollide = true
					break
		if PixelPerfect and rectCollide:
			# build list from self: GetPixels of SpriteSheet slice of CurrentSprite. If a > 0, offset by SpriteRect.x/SpriteRect.y and add to list.
			# repeat for collider.
			# for pixel in list: if pixel in collider.screenPixels: collisionPoint = pixel
			# NOT COMPATIBLE WITH SCALING. WHAT DO I DO
			Debug.LogError("NYI: pixel-perfect ykcSprite/ykcSprite collision")

		return collisionPoint


	def Animate ():
		# support function - called automatically every frame. Advance animation and set new sprite if needed.
		if self.AnimationActive == true and (Time.time * 1000) >= self.AnimationTimer:
			# animation timeout reached
			if self.CurrentSprite[0] == AnimationFrames and AnimationLoop == true:
				# max frame reached and need to loop
				self.SetFrame((0, self.CurrentSprite[1]))
				self.AnimationTimer = (Time.time * 1000) + self.AnimationSpeed
			elif self.CurrentSprite[0] == AnimationFrames and AnimationLoop == false:
				# max frame reached and no loop, stop anim timer
				self.AnimationTimer = 0
				self.AnimationActive = false
				self.AnimationSpeed = 0
				self.AnimationFrames = 0
			else:
				# advance frame, reset animation timer
				self.SetFrame((self.CurrentSprite[0] + self.AnimationDirection, self.CurrentSprite[1]))
				self.AnimationTimer = (Time.time * 1000) + self.AnimationSpeed


	def GetAngle (target as Vector2):
		# calculate angle between self and Vector2 target. Useful for adjusting sprite rotation.
		VerticalVector = Vector2(0, 1)
		TargetVector = self.SpriteRect.center - target
		angle = Vector2.Angle(TargetVector, VerticalVector)
		cross = Vector3.Cross(TargetVector, VerticalVector)
		if cross.z > 0:
	   		angle = 360 - angle
	   	return angle


	def GetVector (target as Vector2):
		# return vector between sprite and Vector2 target. Useful for making sprites move towards other sprites.
		# 		self.spriteRect.center -= self.GetVector(target.spriteRect.center)
		returnVector as Vector2
		returnVector = self.SpriteRect.center - target
		returnVector.Normalize()
		return returnVector
	

	def OnGUI ():
		self.CollisionRect.center = self.SpriteRect.center
		if self.ManualDraw == false and self.Visible == true:
			self.Draw()
