extends PiecePanel

const separation = 107

# Set while an enemy's hide_preview is active: the queue draws as empty. The last
# bags are kept so lifting it redraws at once rather than on the next spawn.
var concealed := false
var _lastCurrent: Array = []
var _lastNext: Array = []

func drawPieces(currentBag, nextBag):
	_lastCurrent = currentBag if currentBag else []
	_lastNext = nextBag if nextBag else []
	Utilities.delete_children(self)
	if concealed:
		return
	var fullQueue = _lastCurrent.duplicate()
	fullQueue.append_array(_lastNext)
	for i in range(mini(PlayerManager.visibleNextPiece, fullQueue.size())):
		drawPiece(fullQueue[i], i*separation)

func setConcealed(value: bool):
	concealed = value
	drawPieces(_lastCurrent, _lastNext)
