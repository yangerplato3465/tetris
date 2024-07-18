extends PiecePanel

const separation = 105

func drawPieces(currentBag, nextBag):
	Utilities.delete_children(self)
	var fullQueue = currentBag.duplicate()
	fullQueue.append_array(nextBag)
	for i in range(PlayerManager.visibleNextPiece):
		drawPiece(fullQueue[i], i*separation)
