# Sprite Manager class to allow ordered drawing of ykcSprite objects
# 2012 Florian Piesche, florian@yellowkeycard.net
# License: http://creativecommons.org/licenses/by-sa/3.0/

import UnityEngine

class ykcSpriteManager(MonoBehaviour):

	public Layers as Hash = {}


	def AddLayer (LayerName as string):
		# add LayerName to Layers
		self.Layers.Add(LayerName, (null))


	def AddSprite (LayerName as string, Sprite as ykcSprite):
		# disable automatic draw on Sprite and add Sprite to LayerName
		self.Layers.Add(LayerName, Sprite)
		Sprite.ManualDraw = true
		return LayerName


	def PurgeSprite (Sprite as ykcSprite):
		# remove Sprite from any and all layers
		layerList = (string)
		for Layer in self.GetLayerNames():
			if Sprite in self.Layers[Layer]:
				self.Layers[Layer].Remove(Sprite)
				layerList.Add(Layer)
		return layerList


	def RemoveSprite (LayerName as string, Sprite as ykcSprite):
		# remove Sprite from specific layer
		if Sprite in self.Layers[LayerName]:
			self.Layers[LayerName].Remove(Sprite)
			return LayerName
		else:
			return ""


	def GetLayerNames ():
		# returns a list of layers (as string)
		return self.Layers.Keys.ToString()


	def FindSprite (Sprite as ykcSprite):
		# returns a list of layers that Sprite was found on
		layerList = (string)
		for Layer in self.GetLayerNames():
			if Sprite in self.Layers[Layer]:
				layerList.Add(Layer)
		return layerList


	def GetSprites ():
		# returns all sprites on a layer as a list.
		return self.Layers[LayerName]


	def OnGUI ():
		for Layer in self.Layers.keys():
			for Sprite in self.Layers[Layer]:
				Sprite.Draw()
