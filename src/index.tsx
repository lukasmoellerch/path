import * as React from 'react';
import * as ReactDOM from "react-dom";
import { setupRenderer } from "./Renderer";
import "./styles.less";
interface Props {
    name: string
}

class App extends React.Component<Props> {
    private stepInput: HTMLInputElement;
    constructor(props) {
        super(props);
        this.stepInput = null;
        this.setStepInputRef = element => {
            setupRenderer(element);
            this.stepInput = element;
        };
    }
    render() {
        return <canvas ref={this.setStepInputRef}></canvas>;
    }
}

var mountNode = document.getElementById("app");
ReactDOM.render(<App name="Jane" />, mountNode);