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
	public CollisionMask as (,)
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
		self.SetSprite((0,0))
		self.CollisionRect.width = collisionSize[0]
		self.CollisionRect.height = collisionSize[1]
		self.AnimationActive = false
		self.Visible = true
		self.ManualDraw = false


	def UpdateCollisionMask ():
		self.CollisionMask = [,]
		# update self.CollisionMask with an 8bit representation of CurrentSprite's alpha channel
		currentSpriteOffset = (self.CurrentSprite[0] * self.SpriteSize[0], self.CurrentSprite[1] * self.SpriteSize[1])
		visibleSprite = self.SpriteSheet.GetPixels(currentSpriteOffset[0], currentSpriteOffset[1], self.SpriteSize[0], self.SpriteSize[1], 0)
		currentCol = 0
		currentRow = 0
		for row in visibleSprite:
			for pixelData in row:
				Debug.LogError(pixelData.ToString())
				self.CollisionMask[currentRow, currentCol] = pixelData.a
				CurrentCol += 1
			CurrentRow += 1
			CurrentCol = 0
		if self.SpriteSize[0] != self.SpriteRect.width or self.SpriteSize[1] != self.SpriteRect.height:
			# scale collision map here. Maybe use TextureScale - http://wiki.unity3d.com/index.php?title=TextureScale
			Debug.Log("Sprite is scaled on screen, need to scale collision map")


	def SetPosition (position as (int), center as bool):
		# offset position by half sprite size to center
		if center == true:
			position[0] -= self.SpriteRect.width / 2
			position[1] -= self.SpriteRect.width / 2
		# place sprite at (int) pixel coordinates
		self.SpriteRect = Rect(position[0], position[1], self.SpriteRect.width, self.SpriteRect.height)
		self.CollisionRect = Rect(position[0] + self.SpriteRect.width, position[1] + self.SpriteRect.height, self.CollisionRect.width, self.CollisionRect.height)


	def Scale (factor as (int), center as bool):
		# scale sprite by factor. Keep centered if center == true.
		self.SetSize((self.SpriteRect.width * factor[0], self.SpriteRect.height * factor[1]), center)


	def SetSize (newSize as (int), center as bool):
		# set sprite size to newSize. Keep centered if center == true.
		if center == true:
			posOffset = (self.SpriteRect.size - newSize) / 2
			self.SpriteRect.position += posOffset
			self.CollisionRect.position += posOffset
		self.spriteRect.size = newSize
		sizeFactor = self.SpriteRect.size / newSize
		self.CollisionRect.size = self.CollisionRect.size * sizeFactor
		return newSize, self.CollisionRect.size


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
		self.SetSprite((0, rowToSet))
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
		if not PixelPerfect:
			# check collision between self.SpriteRect and collider; returns first collision point
			for yCheck in range(collider.y, collider.y + collider.height):
				for xCheck in range(collider.x, collider.x + collider.width):
					if self.CollisionRect.Contains(Vector2(xCheck, yCheck)):
						return (xCheck, yCheck)
			return false


	def CollideCheckSprite (collider as ykcSprite, PixelPerfect as bool):
		if not PixelPerfect:
			# check collision between self.SpriteRect and collider.SpriteRect, returns first collision point
			for yCheck in range(collider.CollisionRect.y, collider.CollisionRect.y + collider.CollisionRect.height):
				for xCheck in range(collider.CollisionRect.x, collider.CollisionRect.x + collider.CollisionRect.width):
					if self.CollisionRect.Contains(Vector2(xCheck, yCheck)):
						return (xCheck, yCheck)
			return false


	def Animate ():
		# support function - called automatically every frame. Advance animation and set new sprite if needed.
		if self.AnimationActive == true and (Time.time * 1000) >= self.AnimationTimer:
			# animation timeout reached
			if self.CurrentSprite[0] == AnimationFrames and AnimationLoop == true:
				# max frame reached and need to loop
				self.SetSprite((0, self.CurrentSprite[1]))
				self.AnimationTimer = (Time.time * 1000) + self.AnimationSpeed
			elif self.CurrentSprite[0] == AnimationFrames and AnimationLoop == false:
				# max frame reached and no loop, stop anim timer
				self.AnimationTimer = 0
				self.AnimationActive = false
				self.AnimationSpeed = 0
				self.AnimationFrames = 0
			else:
				# advance frame, reset animation timer
				self.SetSprite((self.CurrentSprite[0] + self.AnimationDirection, self.CurrentSprite[1]))
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
