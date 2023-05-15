*** Settings ***
Documentation       Sets the encryption key in the vault with a generated key.
...                 NOTE: The vault needs to be first created in Control Room.
...                 NOTE2: Only run when you want to change the encryption key.
Library     RPA.Crypto
Library     RPA.Robocorp.Vault
Library     Collections

*** Variables ***
${VAULTNAME}     WIEncryption
${KEYNAME}       key

*** Tasks ***
Generate key to Vault
    ${key}=     Generate key
    ${secret}=          Get Secret      ${VAULTNAME}
    Set To Dictionary   ${secret}       ${KEYNAME}    ${key}
    Set Secret    ${secret}