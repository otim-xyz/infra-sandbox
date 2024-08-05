use alloy::sol;

sol! {
    #[sol(rpc)]
    interface Fibonacci {
        #[derive(Debug)]
        event NumberF0Set(uint256 f0, uint256 newF0);
        #[derive(Debug)]
        event NumberF1Set(uint256 f1, uint256 newF1);

        #[derive(Debug)]
        error F0NotEqualToF1(uint256 f0, uint256 newF0, uint256 f1);
        #[derive(Debug)]
        error F1NotFibonacci(uint256 f0, uint256 f1, uint256 newF1);

        #[derive(Debug)]
        function setF0F1(uint256 newF0, uint256 newF1) public;
        #[derive(Debug)]
        function getCurrentValues() public view returns (uint256, uint256);
    }
}
