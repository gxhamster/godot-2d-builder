extends Entity


const REGIONS := [
	Rect2(10, 560, 210, 210),
	Rect2(230, 560, 210, 210),
	Rect2(450, 560, 210, 210),
	Rect2(670, 560, 210, 210),
]


func _ready() -> void:
	$Foliage.region_rect = REGIONS[int(rand_range(0, REGIONS.size() - 1))]
