extends Node

func _getAlphaFromPoints(from: float, to: float, at: float) -> float:
	if at <= from: return 0
	elif at >= to: return 1
	return (at - from) / (to - from)

enum EasingStyle {
	Linear = 0,
	Sine = 1,
	Back = 2,
	Quad = 3,
	Quart = 4,
	Quint = 5,
	Bounce = 6,
	Elastic = 7,
	Exponential = 8,
	Circular = 9,
	Cubic = 10,
}

enum EasingDirection {
	In = 0,
	Out = 1,
	InOut = 2,
}

enum PlaybackStateEnum {
	Begin = 0,
	Delayed = 1,
	Playing = 2,
	Paused = 3,
	Completed = 4,
	Cancelled = 5,
}

class TweenInfo:
	var _time = 0
	var _easingStyle = 0
	var _easingDirection = 0
	var _repeatCount = 0
	var _reverses = false
	var _delayTime = 0
	func _init(time: float, easingStyle: EasingStyle, easingDirection: EasingDirection, repeatCount: int = 0, reverses: bool = false, delayTime: float = 0) -> void:
		_time = time
		_easingStyle = easingStyle
		_easingDirection = easingDirection
		_repeatCount = repeatCount
		_reverses = reverses
		_delayTime = delayTime

class TSTween:
	signal Completed(playbackState: PlaybackStateEnum)
	
	var _Instance = null
	var _TweenInfo: TweenInfo = null
	var _GoalTable = {}
	var _OriginalTable = {}
	var PlaybackState = null
	
	var startTime = 0
	var endTime = 0
	var alphaOffset = 0
	
	func Play() -> void:
		startTime = Time.get_ticks_msec() / 1000.0 + _TweenInfo._delayTime
		endTime = startTime + _TweenInfo._time + _TweenInfo._delayTime
		if _TweenInfo._delayTime > 0:
			PlaybackState = PlaybackStateEnum.Delayed
		else:
			PlaybackState = PlaybackStateEnum.Playing
	
	func Pause() -> void:
		alphaOffset = _getAlphaFromPoints(startTime, endTime, Time.get_ticks_msec() / 1000.0)
		PlaybackState = PlaybackStateEnum.Paused
	
	func Cancel() -> void:
		alphaOffset = 0
		PlaybackState = PlaybackStateEnum.Cancelled
		Completed.emit(PlaybackStateEnum.Cancelled)
	
	func _getAlphaFromPoints(from: float, to: float, at: float) -> float:
		if at <= from: return 0
		elif at >= to: return 1
		return (at - from) / (to - from)

var _tweens: Array[TSTween] = []

func Create(instance: Node, tweenInfo: TweenInfo, propertyTable: Dictionary):
	for tween in _tweens:
		if tween._Instance == instance:
			tween.Cancel()
	var tween = TSTween.new()
	tween._Instance = instance
	tween._TweenInfo = tweenInfo
	tween._GoalTable = propertyTable
	tween.PlaybackState = PlaybackStateEnum.Begin
	_tweens.push_back(tween)
	return tween

func interpolateValue(style: EasingStyle, direction: EasingDirection, from: float, to: float, alpha: float) -> float:
	if style == EasingStyle.Linear:
		pass
	elif style == EasingStyle.Sine and direction == EasingDirection.In:
		alpha = 1 - cos((alpha * PI) / 2)
	elif style == EasingStyle.Sine and direction == EasingDirection.Out:
		alpha = sin((alpha * PI) / 2)
	elif style == EasingStyle.Sine and direction == EasingDirection.InOut:
		alpha = -(cos(PI * alpha) - 1) / 2
	elif style == EasingStyle.Back and direction == EasingDirection.In:
		var c1 = 1.70158
		var c3 = c1 + 1
		alpha = c3 * alpha * alpha * alpha - c1 * alpha * alpha
	elif style == EasingStyle.Back and direction == EasingDirection.Out:
		var c1 = 1.70158
		var c3 = c1 + 1
		alpha = 1 + c3 * pow(alpha - 1, 3) + c1 * pow(alpha - 1, 2)
	elif style == EasingStyle.Back and direction == EasingDirection.InOut:
		var c1 = 1.70158
		var c2 = c1 * 1.525
		if alpha < 0.5:
			alpha = (pow(2 * alpha, 2) * ((c2 + 1) * 2 * alpha - c2)) / 2
		else:
			alpha = (pow(2 * alpha - 2, 2) * ((c2 + 1) * (alpha * 2 - 2) + c2) + 2) / 2
	elif style == EasingStyle.Quad and direction == EasingDirection.In:
		alpha = alpha * alpha
	elif style == EasingStyle.Quad and direction == EasingDirection.Out:
		alpha = 1 - (1 - alpha) * (1 - alpha)
	elif style == EasingStyle.Quad and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = 2 * alpha * alpha
		else:
			alpha = 1 - pow(-2 * alpha + 2, 2) / 2
	elif style == EasingStyle.Quart and direction == EasingDirection.In:
		alpha = alpha * alpha * alpha * alpha
	elif style == EasingStyle.Quart and direction == EasingDirection.Out:
		alpha = 1 - pow(1 - alpha, 4)
	elif style == EasingStyle.Quart and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = 8 * alpha * alpha * alpha * alpha
		else:
			alpha = 1 - pow(-2 * alpha + 2, 4) / 2
	elif style == EasingStyle.Quint and direction == EasingDirection.In:
		alpha = alpha * alpha * alpha * alpha * alpha
	elif style == EasingStyle.Quint and direction == EasingDirection.Out:
		alpha = 1 - pow(1 - alpha, 5)
	elif style == EasingStyle.Quint and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = 16 * alpha * alpha * alpha * alpha * alpha
		else:
			alpha = 1 - pow(-2 * alpha + 2, 5) / 2
	elif style == EasingStyle.Bounce and direction == EasingDirection.In:
		alpha = 1 - alpha
		var n1 = 7.5625
		var d1 = 2.75
		if alpha < 1 / d1:
			alpha = n1 * alpha * alpha
		elif alpha < 2 / d1:
			var res = n1 * (alpha - 1.5 / d1)
			alpha -= 1.5
			alpha = res * alpha + 0.75
		elif alpha < 2.5 / d1:
			var res = n1 * (alpha - 2.25 / d1)
			alpha -= 2.25
			alpha = res * alpha + 0.9375
		else:
			var res = n1 * (alpha - 2.625 / 31)
			alpha -= 2.625
			alpha = res * alpha + 0.984375
	elif style == EasingStyle.Bounce and direction == EasingDirection.Out:
		var n1 = 7.5625
		var d1 = 2.75
		if alpha < 1 / d1:
			alpha = n1 * alpha * alpha
		elif alpha < 2 / d1:
			var res = n1 * (alpha - 1.5 / d1)
			alpha -= 1.5
			alpha = res * alpha + 0.75
		elif alpha < 2.5 / d1:
			var res = n1 * (alpha - 2.25 / d1)
			alpha -= 2.25
			alpha = res * alpha + 0.9375
		else:
			var res = n1 * (alpha - 2.625 / 31)
			alpha -= 2.625
			alpha = res * alpha + 0.984375
	elif style == EasingStyle.Bounce and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = 1 - 2 * alpha
			var n1 = 7.5625
			var d1 = 2.75
			if alpha < 1 / d1:
				alpha = n1 * alpha * alpha
			elif alpha < 2 / d1:
				var res = n1 * (alpha - 1.5 / d1)
				alpha -= 1.5
				alpha = res * alpha + 0.75
			elif alpha < 2.5 / d1:
				var res = n1 * (alpha - 2.25 / d1)
				alpha -= 2.25
				alpha = res * alpha + 0.9375
			else:
				var res = n1 * (alpha - 2.625 / 31)
				alpha -= 2.625
				alpha = res * alpha + 0.984375
			alpha = (1 - alpha) / 2
		else:
			alpha = 2 * alpha - 1
			var n1 = 7.5625
			var d1 = 2.75
			if alpha < 1 / d1:
				alpha = n1 * alpha * alpha
			elif alpha < 2 / d1:
				var res = n1 * (alpha - 1.5 / d1)
				alpha -= 1.5
				alpha = res * alpha + 0.75
			elif alpha < 2.5 / d1:
				var res = n1 * (alpha - 2.25 / d1)
				alpha -= 2.25
				alpha = res * alpha + 0.9375
			else:
				var res = n1 * (alpha - 2.625 / 31)
				alpha -= 2.625
				alpha = res * alpha + 0.984375
			alpha = (1 + alpha) / 2
	elif style == EasingStyle.Elastic and direction == EasingDirection.In:
		if alpha != 0 and alpha != 1:
			var c4 = (2 * PI) / 3
			alpha = -pow(2, 10 * alpha - 10) * sin((alpha * 10 - 10.75) * c4)
	elif style == EasingStyle.Elastic and direction == EasingDirection.Out:
		if alpha != 0 and alpha != 1:
			var c4 = (2 * PI) / 3
			alpha = pow(2, -10 * alpha) * sin((alpha * 10 - 0.75) * c4) + 1
	elif style == EasingStyle.Elastic and direction == EasingDirection.InOut:
		if alpha != 0 and alpha != 1 and alpha < 0.5:
			var c5 = (2 * PI) / 4.5
			alpha = -(pow(2, 20 * alpha - 10) * sin((20 * alpha - 11.125) * c5)) / 2
		elif alpha != 0 and alpha != 1 and alpha >= 0.5:
			var c5 = (2 * PI) / 4.5
			alpha = (pow(2, -20 * alpha + 10) * sin((20 * alpha - 11.125) * c5)) / 2 + 1
	elif style == EasingStyle.Exponential and direction == EasingDirection.In:
		if alpha != 0:
			alpha = pow(2, 10 * alpha - 10)
	elif style == EasingStyle.Exponential and direction == EasingDirection.Out:
		if alpha != 1:
			alpha = 1 - pow(2, -10 * alpha)
	elif style == EasingStyle.Exponential and direction == EasingDirection.InOut:
		if alpha != 0 and alpha != 1 and alpha < 0.5:
			alpha = pow(2, 20 * alpha - 10) / 2
		elif alpha != 0 and alpha != 1 and alpha >= 0.5:
			alpha = (2 - pow(2, -20 * alpha + 10)) / 2
	elif style == EasingStyle.Circular and direction == EasingDirection.In:
		alpha = 1 - sqrt(1 - pow(alpha, 2))
	elif style == EasingStyle.Circular and direction == EasingDirection.Out:
		alpha = sqrt(1 - pow(alpha - 1, 2))
	elif style == EasingStyle.Circular and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = (1 - sqrt(1 - pow(2 * alpha, 2))) / 2
		else:
			alpha = (sqrt(1 - pow(-2 * alpha + 2, 2)) + 1) / 2
	elif style == EasingStyle.Cubic and direction == EasingDirection.In:
		alpha = alpha * alpha * alpha
	elif style == EasingStyle.Cubic and direction == EasingDirection.Out:
		alpha = 1 - pow(1 - alpha, 3)
	elif style == EasingStyle.Cubic and direction == EasingDirection.InOut:
		if alpha < 0.5:
			alpha = 4 * alpha * alpha * alpha
		else:
			alpha = 1 - pow(-2 * alpha + 2, 3) / 2
	return from + alpha * (to - from)

func interpolate(style: EasingStyle, direction: EasingDirection, from: Variant, to: Variant, alpha: float) -> Variant:
	if to is float:
		return interpolateValue(style, direction, from, to, alpha)
	elif to is int:
		return int(interpolateValue(style, direction, from, to, alpha))
	elif to is bool:
		var fromB = 0
		var toB = 0
		if from: fromB = 1
		if to: toB = 1
		return interpolateValue(style, direction, fromB, toB, alpha) > 0.5
	elif to is String:
		return to.substr(0, interpolateValue(style, direction, 0, to.length(), alpha))
	elif to is Rect2:
		return Rect2(
			interpolateValue(style, direction, from.position.x, to.position.x, alpha),
			interpolateValue(style, direction, from.position.y, to.position.y, alpha),
			interpolateValue(style, direction, from.size.x, to.size.x, alpha),
			interpolateValue(style, direction, from.size.y, to.size.y, alpha))
	elif to is Rect2i:
		return Rect2i(
			int(interpolateValue(style, direction, from.position.x, to.position.x, alpha)),
			int(interpolateValue(style, direction, from.position.y, to.position.y, alpha)),
			int(interpolateValue(style, direction, from.size.x, to.size.x, alpha)),
			int(interpolateValue(style, direction, from.size.y, to.size.y, alpha)))
	elif to is Vector2:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		return Vector2(x, y)
	elif to is Vector2i:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		return Vector2i(int(x), int(y))
	elif to is Vector3:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		var z = interpolateValue(style, direction, from.z, to.z, alpha)
		return Vector3(x, y, z)
	elif to is Vector3i:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		var z = interpolateValue(style, direction, from.z, to.z, alpha)
		return Vector3i(int(x), int(y), int(z))
	elif to is Vector4:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		var z = interpolateValue(style, direction, from.z, to.z, alpha)
		var w = interpolateValue(style, direction, from.w, to.w, alpha)
		return Vector4(x, y, z, w)
	elif to is Vector4i:
		var x = interpolateValue(style, direction, from.x, to.x, alpha)
		var y = interpolateValue(style, direction, from.y, to.y, alpha)
		var z = interpolateValue(style, direction, from.z, to.z, alpha)
		var w = interpolateValue(style, direction, from.w, to.w, alpha)
		return Vector4i(int(x), int(y), int(z), int(w))
	elif to is Color:
		var r = interpolateValue(style, direction, from.r, to.r, alpha)
		var g = interpolateValue(style, direction, from.g, to.g, alpha)
		var b = interpolateValue(style, direction, from.b, to.b, alpha)
		return Color(r, g, b)
	elif interpolateValue(style, direction, 0, 1, alpha) < 0.5: return from
	else: return to

func _process(_delta: float) -> void:
	for tween: TSTween in _tweens:
		if tween.PlaybackState == PlaybackStateEnum.Delayed and Time.get_ticks_msec() / 1000.0 >= tween.startTime:
			tween.PlaybackState = PlaybackStateEnum.Playing
		if tween.PlaybackState != PlaybackStateEnum.Playing: continue
		var alpha = _getAlphaFromPoints(tween.startTime, tween.endTime, Time.get_ticks_msec() / 1000.0)
		if alpha == 0:
			alpha = tween.alphaOffset
		if alpha >= 1:
			tween.PlaybackState = PlaybackStateEnum.Completed
			tween.Completed.emit(tween.PlaybackState)
			_tweens.remove_at(_tweens.find(tween))
		else:
			for k in tween._GoalTable:
				if not tween._OriginalTable.has(k): tween._OriginalTable[k] = tween._Instance[k]
				var style = tween._TweenInfo._easingStyle
				var direction = tween._TweenInfo._easingDirection
				var from = tween._OriginalTable[k]
				var to = tween._GoalTable[k]
				tween._Instance[k] = interpolate(style, direction, from, to, alpha)
