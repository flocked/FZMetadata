# ``MetadataQuery/Predicate``

## Topics

### Accessing Metadata attributes

- ``subscript(dynamicMember:)-4qgjn``
- ``subscript(dynamicMember:)-1qiyu``

### General

- ``isFile``
- ``isDirectory``
- ``isAlias``
- ``isVolume``
- ``any``

### Equatable

- ``isNil``
- ``isNotNil``
- ``in(_:)``
- ``&&(_:_:)``
- ``||(_:_:)``
- ``!(_:)``
- ``==(_:_:)-3tdn8``
- ``==(_:_:)-5kf3l``
- ``==(_:_:)-7sug5``
- ``==(_:_:)-7yucj``
- ``==(_:_:)-8bvu6``
- ``==(_:_:)-96169``
- ``==(_:_:)-31p4h``
- ``==(_:_:)-2ubyi``
- ``!=(_:_:)-1xq7f``
- ``!=(_:_:)-6sqnt``
- ``!=(_:_:)-1wcwb``
- ``!=(_:_:)-5rqbe``

### Comparable

- ``==(_:_:)-1hl1w``
- ``==(_:_:)-1q5o9``
- ``>(_:_:)``
- ``>=(_:_:)``
- ``<(_:_:)``
- ``<=(_:_:)``
- ``between(_:)-3u294``
- ``between(_:)-51xg1``
- ``between(any:)-38gco``
- ``between(any:)-8ztwv``


### String

- ``begins(with:_:)``
- ``begins(withAny:_:)``
- ``ends(with:_:)``
- ``ends(withAny:_:)``
- ``contains(_:_:)``
- ``contains(any:_:)``
- ``equals(_:_:)``
- ``equals(any:_:)``
- ``equalsNot(_:_:)-21m62``
- ``equalsNot(_:_:)-72dcm``
- ``*==(_:_:)-2ws0t``
- ``*==(_:_:)-7xntd``
- ``==*(_:_:)-8zg0a``
- ``==*(_:_:)-rzgf``
- ``*=*(_:_:)-274ns``
- ``*=*(_:_:)-7ijg7``
- ``MetadataQuery/PredicateStringOptions``

### Date

- ``isNow``
- ``isToday``
- ``isThisHour``
- ``isYesterday``
- ``isSameDay(as:)``
- ``isThisWeek``
- ``isLastWeek``
- ``isSameWeek(as:)``
- ``isThisMonth``
- ``isLastMonth``
- ``isSameMonth(as:)``
- ``isThisYear``
- ``isLastYear``
- ``isSameYear(as:)``
- ``isBefore(_:)``
- ``isAfter(_:)``
- ``within(_:_:)``
- ``this(_:)``
- ``between(_:)-7axbv``

### Collection

- ``contains(_:)``
- ``containsNot(_:)``
- ``contains(any:)``
- ``containsNot(any:)``
- ``==(_:_:)-9m89j``
- ``!=(_:_:)-8cjp0``

### UTType

- ``subtype(of:)-91z0u``
- ``subtype(of:)-9vizg``

### Type Conformances

Types that can be used for constructing a predicate.

- ``FZMetadata/QueryCollection``
- ``FZMetadata/QueryComparable``
- ``FZMetadata/QueryDate``
- ``FZMetadata/QueryEquatable``
- ``FZMetadata/QueryFileType``
- ``FZMetadata/QueryString``
- ``FZMetadata/QueryUTType``
- ``UniformTypeIdentifiers/UTType``
- ``Swift/Optional``
- ``FZSwiftUtils/DataSize``
- ``FZSwiftUtils/TimeDuration``
