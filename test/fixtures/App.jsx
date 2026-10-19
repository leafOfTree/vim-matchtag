import React from 'react';


export function App({ name }) {
  const items = ['a', 'b'];
  return (
    <div className="app">
      <h1>Hello {name}</h1>
      <ul>
        {items.map((i) => (
          <li key={i}>{i}</li>
        ))}
      </ul>
    </div>
  );
}
