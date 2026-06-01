import { Controller } from "@hotwired/stimulus";

import Toastify from "toastify";

export default class extends Controller {

    static values = {
        messageType: String,
        messageText: String
    };

    static bgMap = {
        notice: "linear-gradient(to right, #60a5fa, #3b82f6)",  // deeper blue to blue-600
        alert: "linear-gradient(to right, #f87171, #ef4444)",   // red-400 to red-600
        success: "linear-gradient(to right, #34d399, #22c55e)", // green-400 to green-600
        warning: "linear-gradient(to right, #facc15, #f59e0b)"  // amber-400 to amber-600
    };

    connect() {
        this.show();
    }

    show = () => {
        const text = this.messageTextValue;

        const type = this.messageTypeValue;
        const bgColor = this.constructor.bgMap[type];

        Toastify({
            text,
            duration: "3000",
            gravity: "bottom",
            position: "left",
            className: "flash-success",
            style: {
                background: bgColor,
                borderRadius: "8px",
                padding: "12px 20px"
            }
        }).showToast();
    };
}
