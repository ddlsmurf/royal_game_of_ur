module.exports = Utils =
  merge: (target, hashes...) ->
    target ?= {}
    for hash in hashes when hash
      for own key, newValue of hash
        prev = target[key]
        target[key] =
          if prev && typeof prev == 'object' && newValue && typeof newValue == 'object'
            Utils.merge(prev, newValue)
          else
            newValue
    target
