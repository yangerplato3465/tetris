extends PiecePanel

var holdPiece: Piece

func swapPiece(piece: Piece):
	#Swap
	# Rebuilt from a copy of the base shape, which strips elementals and resets the
	# rotation. A copy, not Constants.SHAPES itself: the piece's cells get written
	# later (enchant_piece, a curse), and the shared shape table must never change.
	# A cursed piece keeps its curse — holding parks it, it doesn't cleanse it.
	var colorIndex = piece.baseColorIndex if piece.cursed else piece.getColorIndex()
	piece.shape = Constants.SHAPES[colorIndex - 1].duplicate(true)
	if piece.cursed:
		piece.curse()
	var returnPiece = holdPiece
	holdPiece = piece
	Utilities.delete_children(self)
	drawPiece(piece, 0)
	return returnPiece

func reset():
	holdPiece = null
	Utilities.delete_children(self)
