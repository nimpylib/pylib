
proc getFrameOrNil*(): PFrame =
  when declared(getFrame): getFrame()
  else: nil  # for JS/nims


proc getFrameOrNil*(up: int): PFrame =
  when declared(getFrame):
    result = getFrame()
    for _ in 1..up:
      result = result.prev
  else: nil  # for JS/nims
