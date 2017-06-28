# _internal-dashboards_ Content Pack

Internal Dashboards are set of _Dashboard_ entities for displaying various metrics about the state of the _Stroom_ application and the undelying hardware and file systems.

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Internal Dashboards_ 

    * **Stroom Status** `Dashboard`

        Displays various visualisations related to the current and historic load on the system, typically broken down by _Stroom_ node. Includes:

     * CPU % by node
     
     * Read Event per second by node
     
     * Write Events per second by node
     
     * Pipeline stream processes by node
     
     * Task queue size

    * **Stroom Volumes** `Dashboard`

        Displays the free space available on the mount point for each volume path

