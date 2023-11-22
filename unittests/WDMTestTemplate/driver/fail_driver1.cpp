/*++

Copyright (c) Microsoft Corporation All Rights Reserved

Module Name:

    common.cpp

Abstract:

    Implementation of the BthHfpDevice class.

--*/
#include "fail_driver1.h"
#include "C:\Program Files (x86)\Windows Kits\10\Include\wdf\kmdf\1.15\wdf.h"


//=============================================================================
#pragma code_seg()
VOID BthHfpDevice::EvtBthHfpDeviceNotificationStatusWorkItem(
    _In_ WDFWORKITEM WorkItem)
/*++

Routine Description:

The function processes status notification updates.

Arguments:

WorkItem    - WDF work-item object.

--*/
{
    WorkItem = NULL;
}
//=============================================================================
#pragma code_seg("PAGE")
NTSTATUS
BthHfpDevice::Init(

)
{

    NTSTATUS wiConfig;
    //
    // Allocate a notification WDF work-item.
    //
    WDF_WORKITEM_CONFIG_INIT(&wiConfig, EvtBthHfpDeviceNotificationStatusWorkItem);
    return 0;
}

_Use_decl_annotations_
    NTSTATUS
    DriverEntry(
        PDRIVER_OBJECT DriverObject,
        PUNICODE_STRING RegistryPath)
{
    DriverObject = NULL;
    RegistryPath = NULL;
    return 0;
}

