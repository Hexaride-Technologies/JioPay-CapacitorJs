import { JioPayCapacitorJs } from 'jiopay-capacitorjs';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    JioPayCapacitorJs.echo({ value: inputValue })
}
