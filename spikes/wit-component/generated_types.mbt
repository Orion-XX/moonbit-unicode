// Illustrative output of the WIT-to-MoonBit mapping spike.
pub struct Item {
  id : UInt
  name : String
}

pub enum LookupError {
  Missing
  Denied(String)
}

pub type LookupResult = Result[Item, LookupError]
pub type SessionHandle = UInt
pub type ItemList = Array[Item]
