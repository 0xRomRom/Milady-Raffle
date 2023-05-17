import { ABI } from "./ABI.js";

const raffleWelcomeText = document.querySelector(".raffle-welcome");
const metamaskModal = document.querySelector(".meta-signup-modal");
const raffleModal = document.querySelector(".enter-raffle-modal");
const connectMetamask = document.querySelector(".connect-meta");
const mintCount = document.querySelector(".mint-count");
const playerCount = document.querySelector(".entered-count");
const incrementMintCount = document.querySelector(".inc");
const decrementMintCount = document.querySelector(".dec");
const enterRaffleButton = document.querySelector(".enter-raffle");

window.onload = async () => {
  if (window.ethereum) {
    window.web3 = new Web3(window.ethereum);
    contractInstance = new web3.eth.Contract(ABI, CONTRACT);

    setInterval(async () => {
      const currentEntrants = await contractInstance.methods
        .PLAYER_COUNT()
        .call();
      playerCount.textContent = "";
      playerCount.textContent = `${currentEntrants} of 1000 entries`;
    }, 3000);
  }
};

let account;
const CONTRACT = "0x51472D557e9Ee00D7E51d0c12dd2131EC29d6bbE";
window.web3 = new Web3(window.ethereum);
let contractInstance = new web3.eth.Contract(ABI, CONTRACT);
console.log(contractInstance);
let mintCounter = 0;
const ethMintWeiPrice = +BigInt("10000000000000000").toString().slice(0);

connectMetamask.addEventListener("click", async () => {
  if (!window.ethereum) {
    alert("Install Metamask to continue. Visit https://metamask.io");
    return;
  }
  await window.ethereum.send("eth_requestAccounts");

  window.web3 = new Web3(window.ethereum);

  const accounts = await web3.eth.getAccounts();

  account = accounts[0];

  metamaskModal.classList.add("hidden");
  raffleModal.classList.remove("hidden");

  raffleWelcomeText.innerHTML = `Hey <span class="addy">${account.slice(
    0,
    15
  )}</span>...<br>ready for an on-chain Schizo Poster raffle for only 0.01 ETH?`;
});

incrementMintCount.addEventListener("click", () => {
  if (mintCounter === 5) return;
  mintCounter++;
  mintCount.textContent = mintCounter;
});
decrementMintCount.addEventListener("click", () => {
  if (mintCounter === 0) return;
  mintCounter--;
  mintCount.textContent = mintCounter;
});

enterRaffleButton.addEventListener("click", async () => {
  try {
    await contractInstance.methods.enterRaffle(mintCounter).send({
      from: account,
      value: (ethMintWeiPrice * mintCounter).toString(),
      gas: 300000,
    });
    alert(`Success! ${mintCounter} entries added`);
  } catch (err) {
    alert("Failed to enter...");
  }
});
