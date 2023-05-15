*** Settings ***
Documentation        Decrypt and log work items content.
...                  NOTE: the example work items provided with the
...                  repository will naturally fail to decrypt unless
...                  you have the exact same encryption key as we did.
...                  So please first run the producer to get some of your
...                  own outputs from it.
Library     RPA.Robocorp.WorkItems
Library     RPA.Crypto
Suite Setup   Get the encryption key

*** Tasks ***
Consume items
    [Documentation]    Cycle through work items.
    Use Encryption Key From Vault    WIEncryption
    TRY
        For Each Input Work Item    Handle item
    EXCEPT    AS    ${err}
        Log    ${err}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=APPLICATION
        ...    code=UNCAUGHT_ERROR
        ...    message=${err}
    END

*** Keywords ***
Handle item
    [Documentation]   Decrypt the workitems
    ${payload}=    Get Work Item Variables

    ${plain_text_ID}=  Set Variable    ${payload}[ID]
    ${decrypted_FN}=   Decrypt String    ${payload}[First Name]
    ${decrypted_LN}=   Decrypt String    ${payload}[Last Name]
    ${decrypted_SSN}=  Decrypt String    ${payload}[SSN]

    Log    ID: ${plain_text_ID}
    Log    First Name: ${decrypted_FN}
    Log    Last Name: ${decrypted_LN}
    Log    SSN: ${decrypted_SSN} \n

    Release Input Work Item    DONE

*** Keywords ***
Get the encryption key
    Use Encryption Key From Vault    WIEncryption