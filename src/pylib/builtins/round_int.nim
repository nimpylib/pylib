
import ./round/int_round
import ../noneType

func round*(x: int, _: NoneType): int = int_round.round(x)
export int_round.round

