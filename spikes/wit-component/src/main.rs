use std::{env, fs, path::PathBuf};
use wit_parser::{Resolve, UnresolvedPackageGroup};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = PathBuf::from(env::args().nth(1).unwrap_or_else(|| "fixture.wit".into()));
    let text = fs::read_to_string(&path)?;
    let group = UnresolvedPackageGroup::parse(path.clone(), &text)
        .map_err(|(_, e)| e)?;
    let mut resolve = Resolve::default();
    let id = resolve.push_group(group)?;
    let world_count = resolve.packages.get(id).map(|p| p.worlds.len()).unwrap_or(0);
    let interface_count = resolve.packages.get(id).map(|p| p.interfaces.len()).unwrap_or(0);
    println!("parsed package={:?} interfaces={} worlds={}", id, interface_count, world_count);
    println!("mapping: record -> struct; variant -> enum; list<T> -> Array[T]; result<T,E> -> Result[T,E]; resource -> opaque handle");
    Ok(())
}
