import Foundation

assert(Morse.letters.count == 36)
assert(Set(Morse.letters.values).count == 36)
assert(Morse.letters["..."] == "S")
assert(Morse.letters["---"] == "O")
assert(Morse.letters["......"] == nil)
assert(abs(Morse.unit(wpm: 10) - 0.12) < 0.000001)
assert(Morse.symbol(duration: 0.239, wpm: 10) == ".")
assert(Morse.symbol(duration: 0.240, wpm: 10) == "-")
assert(Morse.unit(wpm: 0) == Morse.unit(wpm: 5))
assert(Morse.unit(wpm: 100) == Morse.unit(wpm: 30))
print("Morse mapping and timing checks passed")
