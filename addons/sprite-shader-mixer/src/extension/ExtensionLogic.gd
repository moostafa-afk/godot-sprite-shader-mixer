class_name ExtensionLogic
extends Object

#SIGNALS
signal onCreateContainerVisible(visible:bool)
signal onDownloadButtonVisible(visible:bool)
signal onSyncButtonVisible(visible:bool)
signal onAddShaderButtonVisible(visible:bool)
signal onShadersCalculated(shadersInserted:Array[ShaderInfo], shadersNotInserted:Array[ShaderInfo])

#RESOURCES
const LOCAL_SHADERS_FOLDER_PATH="res://addons/sprite-shader-mixer/assets/shaders/local"
const SHADERS_JSON_LOCAL_PATH="res://addons/sprite-shader-mixer/assets/shaders/shaders.json"
const SHADERS_JSON_GITHUB_DOMAIN="raw.githubusercontent.com"
const SHADERS_JSON_GITHUB_PATH="/spheras/godot-sprite-shader-mixer/v1/shaders/shaders.json"
const SHADERS_GITHUB_DOMAIN="raw.githubusercontent.com"
const SHADERS_GITHUB_BASE_PATH="/spheras/godot-sprite-shader-mixer/v1/shaders/"
const SHADERS_LOCAL_BASE_PATH="res://addons/sprite-shader-mixer/assets/shaders/"

#PROPERTIES
static var NONE_SHADER:String="None"
var parentSprite #The parent sprite to set the shaders. It can be a Sprite2D or an AnimatedSprite2D
var ALL_LOCAL_SHADERS:Array[ShaderInfo]=[]
var ALL_SHADERS:Array[ShaderInfo]=[] #list of all available shaders
var selectedShaders:Array[ShaderInfo]=[] #list of selected shaders in the sprite
var pendingShaders:Array[ShaderInfo]=[] #list of pending available shaders


func onReady():
	self._checkCreateVisibility()

# Set the parent which is owner of the shader to manipulate
#     parent -> Sprite2D or AnimationSprite2D
func setParentSprite(parent)->void:
	assert(parent is Sprite2D || parent is AnimatedSprite2D || parent is Label || parent is ColorRect)
	self.parentSprite=parent;
	self._checkCreateVisibility()

# find a shader info by its name
#   shaderName -> the name to search
#   return -> the ShaderInfo found or null otherwise
func _findShaderInfo(shaderName:String) -> ShaderInfo:
	for shader in ALL_LOCAL_SHADERS + ALL_SHADERS:
		if(shader.name.match(shaderName)):
			return shader
	return null
	
# Function called when a shader is intended to be added
#    shader -> the shader name to be added
func onAddShaderPressed(shaderName:String)->void:
	for shaderToAdd in pendingShaders:
		if(shaderToAdd.name.match(shaderName)):
			if(shaderToAdd.vertex):
				self.selectedShaders.insert(0,shaderToAdd)
			else:
				self.selectedShaders.append(shaderToAdd)
			self.pendingShaders.erase(shaderToAdd)
			var newShader:Shader=ShaderInfo.generateShaderCode(self.selectedShaders)
			(self.parentSprite.material as ShaderMaterial).shader=newShader
			
			for param in shaderToAdd.parameters:
				if(param.texture!=null && param.texture.length()>0):
					var texturePath=SHADERS_LOCAL_BASE_PATH+param.texture
					var textureRes:CompressedTexture2D=ResourceLoader.load(texturePath)
					(self.parentSprite.material as ShaderMaterial).set_shader_parameter(param.name,textureRes)
			
			self._calculateShadersInserted()
			return

# Function called when the user wants to download a shader from github
#   shaderName -> the name of the shader to download
#   node -> the parent node, just for hack purposes
#   text -> if the download is for testing the shader (true) or we want to really download and run the texture
func onDownloadShaderPressed(shaderName:String, node:Node, test:bool=false)->void:
	var shaderInfo=_findShaderInfo(shaderName)
	if(shaderInfo!=null):
		if shaderInfo.isLocal:
			print(shaderInfo.name, " -- local shader doesnt require download")
		else:
			var shaderGithubPath=SHADERS_GITHUB_BASE_PATH +shaderInfo.filename
			print("Downloading Shader...")
			print("   %s/%s" % [SHADERS_GITHUB_DOMAIN,shaderGithubPath])
			print("please wait...")
			var shaderContent=await UtilHTTP.httpsDownloadJson(SHADERS_GITHUB_DOMAIN, shaderGithubPath)
			var shaderPath=SHADERS_LOCAL_BASE_PATH+shaderInfo.filename
			Util.saveFile(shaderPath,shaderContent)
			print("Saved shader to: ", shaderPath)
			if(!test):
				self.onDownloadButtonVisible.emit(false)
				self.onAddShaderButtonVisible.emit(true)

			#Download vertex code if neceesary
			if(shaderInfo.vertex):
				var vertexGithubPath=SHADERS_GITHUB_BASE_PATH +shaderInfo.vertexCallCode
				var vertexContent=await UtilHTTP.httpsDownloadJson(SHADERS_GITHUB_DOMAIN, vertexGithubPath)
				var vertexPath=SHADERS_LOCAL_BASE_PATH+shaderInfo.vertexCallCode
				Util.saveFile(vertexPath,vertexContent)
				print("Saved vertex to: ", vertexPath)

		var anyTexturePathToSolveBug:String=""
		for param in shaderInfo.parameters:
			if shaderInfo.isLocal:
				continue
			if (!(param as ShaderInfoParameter).textureHasBeenDownloaded()):
				var textureGithubPath=SHADERS_GITHUB_BASE_PATH + param.texture
				print("Downloading Texture...")
				print("   %s/%s" % [SHADERS_GITHUB_DOMAIN,textureGithubPath])
				print("please wait...")
				var byteArray:PackedByteArray=await UtilHTTP.httpsDownloadBinary(SHADERS_GITHUB_DOMAIN,textureGithubPath)
				var texturePath=SHADERS_LOCAL_BASE_PATH+param.texture
				#await Util.saveBinaryFile(texturePath,byteArray)
				var image=Image.new()
				image.load_png_from_buffer(byteArray)
				var texture:ImageTexture=ImageTexture.create_from_image(image)
				ResourceSaver.save(texture,texturePath)
				texture.take_over_path(texturePath)
				anyTexturePathToSolveBug=texturePath
				
				print("Save texture to: ", texturePath)
		
		if !shaderInfo.isLocal:
			print("Downloaded Shader, enjoy.")

		#HACK START
		#ATTENTION: THIS PART, INCLUDED THE OS ALERT (NOT SURE IF THIS HAPPENS IN ALL OS)
		#SOLVE A PROBLEM WITH GODOT. THE POINT IS THAT IF WE SAVE
		#THE RESOURCE, GODOT EDITOR DOESN'T READ IT UNTIL THE WINDOW EDITOR LOST THE FOCUS
		#AND GAIN IT AGAIN. THE ALERT, FORCE THAT.
		#ON THE OTHER HAND, AFTER THAT, WE NEED TO WAIT TO GODOT TO LOAD CORRECTLY
		#THE RESOURCE... AND THAT'S ALL NECESSARY TO SET CORRECTLY ALL THE TEXTURES
		OS.alert("Downloaded Shader, enjoy", 'Import')
		if(anyTexturePathToSolveBug.length()>0):
			#AFTER THE ALERT, WE CAN EXPECT GODOT IS LOADING THE RESOURCE, LET'S WAIT
			var waitingEditorFinished=ResourceLoader.exists(anyTexturePathToSolveBug)
			while(!waitingEditorFinished):
				if(node.is_inside_tree()):
					await node.get_tree().create_timer(0.5).timeout
				waitingEditorFinished=ResourceLoader.exists(anyTexturePathToSolveBug)
			#OK, NOW EVERYTHING SHOULD BE OK TO CONTINUE
			#HACK END

		#Adding it
		if(!test):
			self.onAddShaderPressed(shaderName)


# Function called when a shader has been selected
#     shader -> the shader name selected
func shaderSelected(shaderName:String)->void:
	if(!shaderName.match(NONE_SHADER)):
		var shaderInfo:ShaderInfo=_findShaderInfo(shaderName)
		if(shaderInfo!=null):
			var downloaded=ShaderInfo.shaderHasBeenDownloaded(shaderInfo)
			self.onAddShaderButtonVisible.emit(downloaded)
			self.onDownloadButtonVisible.emit(!downloaded)
			return
	self.onAddShaderButtonVisible.emit(false)
	self.onDownloadButtonVisible.emit(false)

func onSyncLocalShaderList()->void:
	_calculateLocalShadersInserted()

func onSyncShaderList()->void:
	print("Syncing the Shader list from Github... please wait...")
	var jsonContent=await UtilHTTP.httpsDownloadJson(SHADERS_JSON_GITHUB_DOMAIN, SHADERS_JSON_GITHUB_PATH)
	Util.saveFile(SHADERS_JSON_LOCAL_PATH,jsonContent)
	_calculateShadersInserted()
	print("Sync done, enjoy.")

func onReorder(shader:ShaderInfo, after:bool)->void:
	var currentIndex=self.selectedShaders.find(shader)
	var flagModified:bool=false
	if(!after && currentIndex>0):
		self.selectedShaders.remove_at(currentIndex)
		self.selectedShaders.insert(currentIndex-1,shader)
		flagModified=true
	elif(after && currentIndex<selectedShaders.size()-1):
		self.selectedShaders.remove_at(currentIndex)
		self.selectedShaders.insert(currentIndex+1,shader)
		flagModified=true
		
	if(flagModified):
		var newShader:Shader=ShaderInfo.generateShaderCode(self.selectedShaders)
		(self.parentSprite.material as ShaderMaterial).shader=newShader
		self._calculateLocalShadersInserted()
		self._calculateShadersInserted()	

func onDeleteShader(shader:ShaderInfo)->void:
	onQuitShader(shader)
	shader.delete()
	pass

func onQuitShader(shader:ShaderInfo)->void:
	self.selectedShaders.erase(shader)
	self.pendingShaders.append(shader)
	var newShader:Shader=ShaderInfo.generateShaderCode(self.selectedShaders)
	(self.parentSprite.material as ShaderMaterial).shader=newShader
	self._calculateLocalShadersInserted()
	self._calculateShadersInserted()	

# Function called when the create mixed sprite button
func onCreatePressed()->void:
	#Create button pressed. Creating a new empty Shader.
	if(self.parentSprite.material == null):
		self.parentSprite.material=ShaderMaterial.new()
	self.parentSprite.material.shader=ShaderInfo.generateShaderCode([])
	self._checkCreateVisibility()

# Checks if the parent Sprite has a shader already configured
# return -> true if the parent has a shader alredy, false otherwise
func _parentSpriteHasShaderAlready()->bool:
	if(self.parentSprite is Sprite2D || self.parentSprite is AnimatedSprite2D || self.parentSprite is Label || self.parentSprite is ColorRect):
		if(self.parentSprite.material != null):
			if(self.parentSprite.material is ShaderMaterial):
				if(self.parentSprite.material.shader != null):
					return true
	return false

# Check if the create button must be visible, 
# and launch the event if necessary
func _checkCreateVisibility()->void:
	#if parent has shader, showing the shaders management
	#else showing create button for an empty shader
	var createButtonVisible=!_parentSpriteHasShaderAlready()
	self.onCreateContainerVisible.emit(createButtonVisible)
	if(!createButtonVisible):
		self._calculateShadersInserted()
		self._calculateLocalShadersInserted()

# private function to order the shaders by name
func _orderShadersByName(a, b)->bool:
	var compare=(a.name as String).nocasecmp_to(b.name)
	if(compare<0):
		return true
	else:
		return false

# Recopile all the shaders available to be added to the
# sprite, those which hasn't been added yet, and emit
# the evento to force the refill of the combo with those shaders
# and the list of inserted shaders
func _calculateShadersInserted()->void:
	#Reading JSON where are defined all available shaders
	var jsonContent=Util.readJsonFile(SHADERS_JSON_LOCAL_PATH)
	if(jsonContent==null):
		return
	ALL_SHADERS=[]
	var allShaders:Array=jsonContent as Array
	allShaders.sort_custom(_orderShadersByName)
	
	for shaderObj in allShaders:
		var shaderInfo:ShaderInfo=ShaderInfo.new()
		shaderInfo.loadShaderInfo(shaderObj)
		ALL_SHADERS.push_back(shaderInfo)
	self._calculatePendingShaders()

func update_current_shaders():
	self.selectedShaders=ShaderInfo.readCurrentlyActiveShadersFromShaderCode(self.parentSprite.material.shader.code, ALL_LOCAL_SHADERS+ALL_SHADERS)

func _calculateLocalShadersInserted()->void:
	var shader_folder = DirAccess.open(LOCAL_SHADERS_FOLDER_PATH)
	if shader_folder == null:
		print(LOCAL_SHADERS_FOLDER_PATH, " missing!")
		return
	ALL_LOCAL_SHADERS = []
	#Reading folder where are local available mixer shaders are expected
	for fileName in shader_folder.get_files():
		if !fileName.ends_with(".gdshader"):
			continue
		var full_path = LOCAL_SHADERS_FOLDER_PATH.path_join(fileName)
		var shaderInfo:ShaderInfo=ShaderInfo.new()
		var fileNoExt:String = fileName.split(".")[0]
		shaderInfo.loadShaderInfo({
			"name": fileNoExt,
			"group": "local",
			"description": full_path,
			"author": "local",
			"link": "",
			"adaptedBy": "me",
			"license": "MIT",
			"version": "1.0",
			"filename": fileName,
			"activation": fileNoExt.to_upper() + "_active",
			"function": fileNoExt.to_lower(),
			"parameters": []
		})
		ALL_LOCAL_SHADERS.push_back(shaderInfo)
	self._calculatePendingShaders()


# Calculates the pending shaders to be added
# based on the shaders already added
func _calculatePendingShaders()->void:
	self.selectedShaders=ShaderInfo.readCurrentlyActiveShadersFromShaderCode(self.parentSprite.material.shader.code, ALL_LOCAL_SHADERS+ALL_SHADERS)
	
	self.pendingShaders=[]
	for shader in ALL_LOCAL_SHADERS + ALL_SHADERS:
		if(self.selectedShaders.find(shader)<0):
			self.pendingShaders.append(shader)
	self.onShadersCalculated.emit(self.selectedShaders, self.pendingShaders)
