/*pub fn add(left: usize, right: usize) -> usize {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}*/

#[no_mangle]
pub extern "C" fn add(a: i64, b: i64) -> i64 {
    return a + b;
}
