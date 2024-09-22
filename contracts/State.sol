// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {AppStorage} from "./AppStorage.sol";

abstract contract State {
    AppStorage internal s;
}